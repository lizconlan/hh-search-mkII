require 'sinatra'
require 'sunspot'
require 'rest-client'
require 'json'
require 'haml'
require 'active_record'
require 'action_view'

WEBSOLR_URL = "http://127.0.0.1:8983/solr"
PARENT_URL = "http://hansard.millbanksystems.com"


helpers do
  def querystring_builder(option={})
    remove = ""
    page = params[:page].to_i
    sort = params[:sort]
    speaker = params[:speaker]
    type = params[:type]
    
    #time options (mutually exclusive)
    decade = params[:decade]
    century = params[:century]
    year = params[:year]
    month = params[:month]
    day = params[:day]
    
    qs = []
    
    name = option.keys.first
    value = option[name]
    if value.nil?
      eval "#{name.to_s} = nil"
      page = 0
    else
      eval "#{name.to_s} = '#{value}'"
      page = 0 unless name.to_s == "page"
    end
    
    if page and page > 1
      qs << "page=#{page}"
    end
    #time stuff here
    if day
      qs << "day=#{day}"
    elsif month
      qs << "month=#{month}"
    elsif year
      qs << "year=#{year}"
    elsif decade
      qs << "decade=#{decade}"
    elsif century
      qs << "century=#{century}"
    end
    if sort
      qs << "sort=#{sort}"
    end
    if speaker
      qs << "speaker=#{speaker}"
    end
    if type
      qs << "type=#{type}"
    end
    
    qstring = qs.join("&")
    qstring.empty? ? request.path_info : "?#{qstring}"
  end
end

#require './models/person'
require './models/search_result'
#require './models/hansard_reference'

before do
  #dbconfig = YAML::load(File.open 'config/database.yml')[ Sinatra::Application.environment.to_s ]
  #ActiveRecord::Base.establish_connection(dbconfig)
end

get "/" do
  haml(:"search_help")
end

post "/" do
  query = params[:query]
  redirect "/#{query}"
end

get "/:query" do
  do_search
  haml(:"search")
end

def do_search
  page = params[:page]
  @page = page ? page.to_i : 1
  @page = 1 if @page < 1
  @results_start = (@page-1)*10+1
  
  query = params[:query]
  if query
    #reference = HansardReference.create_from(query)
    
    @page_title = "Search: #{query}"
    url = WEBSOLR_URL + "/select/?q=text_texts:#{CGI::escape(query)}&start=#{@results_start-1}&facet=true&facet.field=decade_is&facet.field=year_is&facet.field=sitting_type_ss&facet.field=speaker_uid_ss&wt=json&hl.fragsize=200&hl=true&hl.fl=text_texts&facet.zeros=false"
    #&sort=date_ds+desc
    #&fq=speaker_name_ss:%22Mr%20Isaac%20Corry%22
    #&facet.query=decade_is:1800
  
    response = RestClient.get(url)
    result = JSON.parse(response)
  
    @search_results = []
  
    speaker_data = result["facet_counts"]["facet_fields"]["speaker_uid_ss"]
    if speaker_data.is_a?(Array)
      @speaker_facets = facets_to_hash(speaker_data)
    end
  
    @results_found = result["response"]["numFound"]
    @results_end = @results_start + 9
    @results_end = @results_found if @results_end > @results_found
    @last_page = (@results_found / 10.0).ceil
    speakers = {}
    
    result["response"]["docs"].each do |search_result|
      id = search_result["id"]
      if search_result["speaker_uid_ss"]
        speaker_slug,speaker_name = search_result["speaker_uid_ss"].split("|")
        speakers[speaker_slug] = speaker_name
      end
      @search_results << SearchResult.new(search_result["subject_ss"], search_result["url_ss"], search_result["speaker_uid_ss"], search_result["sitting_type_ss"], search_result["date_ds"], result["highlighting"][id]["text_texts"].join(" "))
    end
    
    @filters = []
    if params[:speaker]
      @speaker_facets[0..5].each do |uuid|
        slug,speaker = uuid.first.split("|")
        if slug == params[:speaker]
          @filters << [speaker, "speaker"]
          break
        end
      end
      
    end
    if params[:type]
      @filters << [params[:type], "type"]
    end
    if params[:day]
    elsif params[:month]
    elsif params[:year]
    elsif params[:decade]
    elsif params[:century]
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

def format_name(uid)
  parts = uid.split("|")
  
  name = parts[1]
end