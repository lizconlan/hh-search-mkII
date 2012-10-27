require 'sinatra'
require 'sunspot'
require 'rest-client'
require 'json'
require 'haml'

require 'active_record'
require './models/person'
require './models/search_result'
require './models/hansard_reference'

before do
  WEBSOLR_URL = "http://127.0.0.1:8983/solr"
  
  dbconfig = YAML::load(File.open 'config/database.yml')[ Sinatra::Application.environment.to_s ]
  ActiveRecord::Base.establish_connection(dbconfig)
  
  PARENT_URL = "http://hansard.millbanksystems.com/"
end

post "/" do
  do_search
  haml(:"search")
end

get "/" do
  do_search
  haml(:"search")
end

def do_search
  query = params[:query]
  if query
    reference = HansardReference.create_from(query)
    
    
    @page_title = "Search: #{query}"
    url = WEBSOLR_URL + "/select/?q=solr_text_texts:#{CGI::escape(query)}&facet=true&facet.field=decade_is&facet.field=year_is&facet.field=sitting_type_ss&facet.field=speaker_url_ss&wt=json&hl.fragsize=150&hl=true&hl.fl=solr_text_texts&facet.zeros=false"
    #&sort=date_ds+desc
    #&fq=speaker_name_ss:%22Mr%20Isaac%20Corry%22
    #&facet.query=decade_is:1800
  
    response = RestClient.get(url)
    result = JSON.parse(response)
  
    html = []
  
    speaker_data = result["facet_counts"]["facet_fields"]["speaker_url_ss"]
    if speaker_data.is_a?(Array)
      speakers = facets_to_hash(speaker_data)
      speaker_list = []
      speakers.each do |name, count|
        speaker_list << "#{format_name(name)} (#{count})"
      end
      @speaker_contributions = speaker_list.join(" ")
    end
  
    @found = result["response"]["numFound"]
    @search_results = []
  
    result["response"]["docs"].each do |search_result|
      id = search_result["id"]
      @search_results << SearchResult.new(search_result["subject_ss"], search_result["url_ss"], search_result["speaker_name_ss"], search_result["speaker_url_ss"], search_result["sitting_type_ss"], search_result["date_ds"], result["highlighting"][id]["solr_text_texts"].join(" "))
    end
  end
end

def facets_to_hash(facet_array)
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

def format_name(url)
  slug = url.split("/").pop
  person = Person.find_by_slug(slug)
  person.name
end