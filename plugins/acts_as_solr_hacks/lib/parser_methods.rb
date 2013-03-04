module ActsAsSolr #:nodoc:
  
  module ParserMethods
    
    protected    
    
    # Method used by mostly all the ClassMethods when doing a search
    def parse_query(query=nil, options={}, models=nil)
      valid_options = [:offset, :limit, :facets, :models, :results_format, :order, :scores, :operator, :highlight]
      query_options = {}
      return if query.nil?
      raise "Invalid parameters: #{(options.keys - valid_options).join(',')}" unless (options.keys - valid_options).empty?
      begin
        Deprecation.validate_query(options)
        query_options[:start] = options[:offset]
        query_options[:rows] = options[:limit]
        query_options[:operator] = options[:operator]
        
        # first steps on the facet parameter processing
        if options[:facets]
          query_options[:facets] = {}
          query_options[:facets][:limit] = -1  # TODO: make this configurable
          query_options[:facets][:sort] = :count if options[:facets][:sort]
          query_options[:facets][:mincount] = 0
          query_options[:facets][:mincount] = 1 if options[:facets][:zeros] == false
          query_options[:facets][:fields] = options[:facets][:fields].collect{|k| "#{k}_facet"} if options[:facets][:fields]
          query_options[:filter_queries] = replace_types(options[:facets][:browse].collect{|k| "#{k.sub!(/ *: */,"_facet:")}"}) if options[:facets][:browse]
          query_options[:facets][:queries] = replace_types(options[:facets][:query].collect{|k| "#{k.sub!(/ *: */,"_t:")}"}) if options[:facets][:query]
        end
        
        if models.nil?
          # TODO: use a filter query for type, allowing Solr to cache it individually
          models = "AND #{solr_configuration[:type_field]}:#{self.name}"
          field_list = solr_configuration[:primary_key_field]
        else
          field_list = "id"
        end
        
        query_options[:field_list] = [field_list, 'score']
        query = "(#{query.gsub(/ *: */,"_t:")}) #{models}"
        order = options[:order].split(/\s*,\s*/).collect{|e| e.gsub(/\s+/,'_t ').gsub(/\bscore_t\b/, 'score')  }.join(',') if options[:order]
        order.gsub!("_facet_t", "_facet") if order
        
        query_options[:query] = replace_types([query])[0] # TODO adjust replace_types to work with String or Array  

        if options[:highlight]
          query_options[:highlighting] = {}
          query_options[:highlighting][:field_list] = []
          query_options[:highlighting][:field_list] << options[:highlight][:fields].collect {|k| "#{k}_t"} if options[:highlight][:fields]
          query_options[:highlighting][:require_field_match] =  options[:highlight][:require_field_match] if options[:highlight][:require_field_match]
          query_options[:highlighting][:max_snippets] = options[:highlight][:max_snippets] if options[:highlight][:max_snippets]
          query_options[:highlighting][:prefix] = options[:highlight][:prefix] if options[:highlight][:prefix]
          query_options[:highlighting][:suffix] = options[:highlight][:suffix] if options[:highlight][:suffix]
          query_options[:highlighting][:fragsize] = options[:highlight][:fragsize] if options[:highlight][:fragsize]
        end

        if options[:order]
          # TODO: set the sort parameter instead of the old ;order. style.
          #query_options[:query]# << ';' << replace_types([order], false)[0]
          query_options[:sort] = order
          
              p "i can (also) haz #{query_options[:sort]}"
        end
        
        RAILS_DEFAULT_LOGGER.info 'sending request'
        result = ActsAsSolr::Post.execute(Solr::Request::Standard.new(query_options))
        RAILS_DEFAULT_LOGGER.info 'sent request'
        result
      rescue
        raise "There was a problem executing your search: #{$!} #{$!.backtrace}"
      end            
    end
    
    
    # Parses the data returned from Solr
    def parse_results(solr_data, options = {})
      RAILS_DEFAULT_LOGGER.info 'parsing results'
      results = {
        :docs => [],
        :total => 0
      }
      configuration = {
        :format => :objects
      }
      results.update(:facets => {'facet_fields' => []}) if options[:facets]
      RAILS_DEFAULT_LOGGER.info 'about to create SearchResults'
      return SearchResults.new(results) if solr_data.total_hits == 0
     
      
      configuration.update(options) if options.is_a?(Hash)

      ids = solr_data.hits.collect {|doc| doc["#{solr_configuration[:primary_key_field]}"]}.flatten
      conditions = [ "#{self.table_name}.#{primary_key} in (?)", ids ]
      result = configuration[:format] == :objects ? reorder(self.find(:all, :conditions => conditions), ids) : ids
      add_scores(result, solr_data) if configuration[:format] == :objects && options[:scores]
      highlighted = {}
      solr_data.highlighting.map do |x,y| 
        e={}
        y1=y.map{|x1,y1| e[x1.gsub(/_[^_]*/,"")]=y1} unless y.nil?
        highlighted[x.gsub(/[^:]*:/,"").to_i]=e
      end unless solr_data.highlighting.nil?

      results.update(:facets => solr_data.data['facet_counts']) if options[:facets]
      results.update({:docs => result, :total => solr_data.total_hits, :max_score => solr_data.max_score})
      results.update({:highlights=>highlighted})
      results = SearchResults.new(results)
      RAILS_DEFAULT_LOGGER.info 'created SearchResults'
      results
    end
  end
end