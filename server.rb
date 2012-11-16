require 'sinatra'
require 'haml'
require 'active_record'
require 'sanitize'
require 'date'

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
      if ["decade", "century", "year", "month", "day"].include?(name.to_s)
        day, month, year, decade, century = nil
      end
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

  def filtered_by_date?
    filter_fields = @filters ? @filters.map{ |_, value| value } : ""
    filter_fields.include?("century") or filter_fields.include?("decade") or filter_fields.include?("year") or filter_fields.include?("month")
  end
end

require './models/person'
require './models/search_result'
require './models/hansard_reference'

require './models/timeline.rb'

require './lib/search'

before do
  dbconfig = YAML::load(File.open 'config/database.yml')
  ActiveRecord::Base.establish_connection(dbconfig)
end

get "/" do
  haml(:"search_help")
end

post "/" do
  query = params[:query]
  redirect "/#{CGI::escape(query)}"
end

get "/:query" do
  @reference = HansardReference.lookup(CGI::unescape(params[:query]))
  if @reference
    @query = Sanitize.clean(CGI::unescape(params[:query]))
    if @reference.match_type == "not stored"
      @page_title = 'Hansard not found'
      haml(:reference_not_found)
    elsif @reference.match_type == "partial"
      @date_match = @reference
    else
      redirect "#{PARENT_URL}#{reference.url}"
    end
  end
  
  if !@reference or @reference.match_type == "partial"
    do_search
    haml(:search)
  end
end

def do_search
  @query = CGI::unescape(params[:query])
  @query = Sanitize.clean(@query)
    
  if @query
    @page_title = "Search: #{@query}"
    
    @people = Person.where("name like ?", "%#{@query}%").order("lastname, name").limit(5)
    @search = Search.new()
    options = {}
    timeline_options = {}
    options[:type] = params[:type] if params[:type]
    options[:speaker] = params[:speaker] if params[:speaker] and Person.find_by_slug(params[:speaker])
    options[:sort] = params[:sort] if params[:sort]
    
    options[:day] = params[:day] if params[:day] and /\d\d\d\d-\d\d?-\d\d?/.match params[:day]
    if params[:month] and /\d\d\d\d-\d\d?/.match params[:month]
      options[:month] = params[:month]
      timeline_options = {:resolution => "month", :month => params[:month]}
    end
    if params[:year] and /\d\d\d\d/.match params[:year]
      options[:year] = params[:year]
      timeline_options = {:resolution => "year", :year => params[:year]}
    end
    if params[:decade] and /\d\d\d\ds/.match params[:decade]
      options[:decade] = params[:decade]
      timeline_options = {:resolution => "decade", :decade => params[:decade]}
    end
    if params[:century] and /C\d\d/.match params[:century]
      options[:century] = params[:century]
      timeline_options = {:resolution => "century", :century => params[:century]}
    end
    
    @search.search(@query, params[:page], options)
    
    if @search.results_found == 0
      @page_title = "Search: no results for '#{@query}'"
    end
    
    @filters = []
    if params[:speaker]
      if (person = Person.find_by_slug(params[:speaker]))
        @filters << ["#{person.honorific} #{person.name}", "speaker"]
      end 
    end
    
    if params[:type]
      @filters << [params[:type], "type"]
    end
    
    if timeline_options[:resolution]
      info = timeline_options[:"#{timeline_options[:resolution]}"]
      label = ""
      if info.include?("-")
        parts = info.split("-")
        if parts[1]
          label = "#{Date::MONTHNAMES[parts[1].to_i]} #{parts[0]}"
        end
      elsif info =~ /C(\d+)/
        label = "#{Timeline.number_to_ordinal($1)} century"
      else
        label = info
      end
      @filters << [label, timeline_options[:resolution]]
    elsif options[:day]
      date = Date.parse(options[:day])
      @filters << ["#{date.day} #{Date::MONTHNAMES[date.month]} #{date.year}", "day"]
    end
    
    unless !filtered_by_date? and @search.results_found == 0 or options[:day]
      @timeline = Timeline.new(@search.date_facets, timeline_options)
    end
  end
end

def format_name(uid)
  parts = uid.split("|")
  name = parts[1]
end