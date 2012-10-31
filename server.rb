require 'sinatra'
require 'sunspot'
require 'haml'
require 'active_record'
#require 'action_view'

WEBSOLR_URL = "http://127.0.0.1:8983/solr"
PARENT_URL = "http://hansard.millbanksystems.com"


helpers do
  def querystring_builder(option={})
    remove = ""
    page = params[:page]
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
    page = page.to_i
    
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

require './lib/search'

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
  query = params[:query]
  if query
    #reference = HansardReference.create_from(query)
    
    @page_title = "Search: #{query}"
    
    @search = Search.new()
    options = {}
    options[:type] = params[:type] if params[:type]
    options[:speaker] = params[:speaker] if params[:speaker]
    
    @search.search(query, params[:page], options)
    
    @filters = []
    if params[:speaker]
      @search.speaker_facets[0..5].each do |uuid|
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