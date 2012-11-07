require 'rest-client'
require 'json'

class Search
  attr_reader :search_results, :speaker_facets, :date_facets, :results_found, :results_end, :results_start, :last_page, :page
  
  def search(query, page, options={})
    @page = page ? page.to_i : 1
    @page = 1 if @page < 1
    @results_start = (@page-1)*10+1
    
    url = WEBSOLR_URL + "/select/?q=text_texts:#{CGI::escape(query)}&start=#{results_start-1}&facet=true&facet.field=date_ds&facet.field=sitting_type_ss&facet.field=speaker_uid_ss&wt=json&hl.fragsize=200&hl=true&hl.fl=text_texts&facet.zeros=false"
    unless options.empty?
      if options[:sort]
        url = "#{url}&sort=date_ds+asc" if options[:sort] == "date"
        url = "#{url}&sort=date_ds+desc" if options[:sort] == "reverse_date"
      end
      
      if options[:speaker]
        url = "#{url}&fq=speaker_url_ss:#{options[:speaker]}"
      end
      if options[:type]
        url = "#{url}&fq=sitting_type_ss:#{CGI::escape(options[:type])}"
      end
    end

    response = RestClient.get(url)
    result = JSON.parse(response)
    
    @search_results = []
    
    result["response"]["docs"].each do |search_result|
      id = search_result["id"]
      @search_results << SearchResult.new(search_result["subject_ss"], search_result["url_ss"], search_result["speaker_uid_ss"], search_result["sitting_type_ss"], search_result["date_ds"], result["highlighting"][id]["text_texts"].join(" "))
    end

    speaker_data = result["facet_counts"]["facet_fields"]["speaker_uid_ss"]
    if speaker_data.is_a?(Array)
      @speaker_facets = facets_to_array(speaker_data)
    end
    
    date_data = result["facet_counts"]["facet_fields"]["date_ds"]
    if date_data.is_a?(Array)
      @date_facets = facets_to_array(date_data)
    end

    @results_found = result["response"]["numFound"]
    @results_end = @results_start + 9
    @results_end = @results_found if @results_end > @results_found
    @last_page = (@results_found / 10.0).ceil
  end
  
  private
    def facets_to_array(facet_array)
      output = {}
      if facet_array.is_a?(Array)
        field_count = ""
        while facet_array.length > 0
          if field_count == ""
            field_count = facet_array.pop.to_i
          else
            output[facet_array.pop] = field_count
            field_count = ""
          end
        end
      end
      output.sort_by{ |name, count| count }.reverse
    end
end