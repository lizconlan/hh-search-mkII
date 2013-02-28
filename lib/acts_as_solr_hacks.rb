# adapted from:
#  https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/acts_as_solr_hacks/lib/search_results.rb
#  https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/acts_as_solr_hacks/lib/parser_methods.rb
#  https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/acts_as_solr_hacks/lib/solr/request/standard.rb

module ActsAsSolr #:nodoc:
  
  class SearchResults
    # Returns the highlighted fields which one has asked for..
    def highlights
      @solr_data[:highlights]
    end
  end
  
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
          query_options[:query] << ';' << replace_types([order], false)[0]
        end
        
        ActsAsSolr::Post.execute(Solr::Request::Standard.new(query_options))
      rescue
        raise "There was a problem executing your search: #{$!}"
      end
    end
  end
end

class Solr::Request::Standard < Solr::Request::Select
  
  VALID_PARAMS = [:query, :sort, :default_field, :operator, :start, :rows,
    :filter_queries, :field_list, :debug_query, :explain_other, :facets, :highlighting]
  
  def initialize(params)
    super('standard')
    
    raise "Invalid parameters: #{(params.keys - VALID_PARAMS).join(',')}" unless 
      (params.keys - VALID_PARAMS).empty?
    
    raise ":query parameter required" unless params[:query]
    
    @params = params.dup
    
    # Validate operator
    if params[:operator]
      raise "Only :and/:or operators allowed" unless 
        [:and, :or].include?(params[:operator])
      
      @params[:operator] = params[:operator].to_s.upcase
    end
    
    # Validate start, rows can be transformed to ints
    @params[:start] = params[:start].to_i if params[:start]
    @params[:rows] = params[:rows].to_i if params[:rows]
    
    @params[:field_list] ||= ["*","score"]
  end
  
  def to_hash
    hash = {}
    
    # standard request param processing
    sort = @params[:sort].collect do |sort|
      key = sort.keys[0]
      "#{key.to_s} #{sort[key] == :descending ? 'desc' : 'asc'}"
    end.join(',') if @params[:sort]
    hash[:q] = sort ? "#{@params[:query]};#{sort}" : @params[:query]
    hash["q.op"] = @params[:operator]
    hash[:df] = @params[:default_field]
    
    # common parameter processing
    hash[:start] = @params[:start]
    hash[:rows] = @params[:rows]
    hash[:fq] = @params[:filter_queries]
    hash[:fl] = @params[:field_list].join(',')
    hash[:debugQuery] = @params[:debug_query]
    hash[:explainOther] = @params[:explain_other]
    
    # facet parameter processing
    if @params[:facets]
      # TODO need validation of all that is under the :facets Hash too
      hash[:facet] = true
      hash["facet.field"] = []
      hash["facet.query"] = @params[:facets][:queries]
      hash["facet.sort"] = (@params[:facets][:sort] == :count) if @params[:facets][:sort]
      hash["facet.limit"] = @params[:facets][:limit]
      hash["facet.missing"] = @params[:facets][:missing]
      hash["facet.mincount"] = @params[:facets][:mincount]
      hash["facet.prefix"] = @params[:facets][:prefix]
      if @params[:facets][:fields]  # facet fields are optional (could be facet.query only)
        @params[:facets][:fields].each do |f|
          if f.kind_of? Hash
            key = f.keys[0]
            value = f[key]
            hash["facet.field"] << key
            hash["f.#{key}.facet.sort"] = (value[:sort] == :count) if value[:sort]
            hash["f.#{key}.facet.limit"] = value[:limit]
            hash["f.#{key}.facet.missing"] = value[:missing]
            hash["f.#{key}.facet.mincount"] = value[:mincount]
            hash["f.#{key}.facet.prefix"] = value[:prefix]
          else
            hash["facet.field"] << f
          end
        end
      end
    end
    
    # highlighting parameter processing - http://wiki.apache.org/solr/HighlightingParameters
    #TODO need to add per-field overriding to snippets, fragsize, requiredFieldMatch, formatting, and simple.pre/post
    if @params[:highlighting]
      hash[:hl] = true
      hash["hl.fl"] = @params[:highlighting][:field_list].join(',') if @params[:highlighting][:field_list]
      hash["hl.snippets"] = @params[:highlighting][:max_snippets]
      hash["hl.requireFieldMatch"] = @params[:highlighting][:require_field_match]
      hash["hl.simple.pre"] = @params[:highlighting][:prefix]
      hash["hl.simple.post"] = @params[:highlighting][:suffix]
      hash["hl.fragsize"] = @params[:highlighting][:fragsize]
    end
    
    hash.merge(super.to_hash)
  end
end