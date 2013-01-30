require 'sinatra'
require 'haml'
require 'active_record'
require 'sanitize'
require 'date'
require './lib/present_on_date/date_extension.rb'
require './helpers/search_helper.rb'

set :logging, true
 
@logger = Logger.new('log/app.log')

WEBSOLR_URL = "http://127.0.0.1:8983/solr"
PARENT_URL = "http://hansard.millbanksystems.com"
RAILS_ROOT = File.dirname(__FILE__)
RAILS_DEFAULT_LOGGER = @logger

LAST_DATE = Date.new(2005, 12, 31)
FIRST_DATE = Date.new(1803, 1, 1)
DEFAULT_FEEDS = [10, 100, 200]

dbconfig = YAML::load(File.open 'config/database.yml')
ActiveRecord::Base.establish_connection(dbconfig)

helpers do
  include SearchHelper
  
  def timeline_options(resolution, sitting_type)
    options = { :upper_nav_limit => LAST_DATE,
                :lower_nav_limit => FIRST_DATE,
                :first_of_month => false,
                :navigation => true,
                :sitting_type => sitting_type }
    options
  end
  
  def params_without(to_remove)
    param_hash = params
    if to_remove.is_a? Array
      to_remove.each do |key|
        param_hash = remove_key(key, param_hash)
      end
    else
      param_hash = remove_key(to_remove, param_hash)
    end
    param_hash
  end

  def remove_key(key, hash)
    key = key.to_s
    hash.reject{|k,v| k==key}
  end
  
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
require './models/hansard_reference'
require './models/contribution'

require './lib/search'
require './lib/date_parser.rb'

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
      redirect "#{PARENT_URL}#{@reference.url}"
    end
  end
  
  if !@reference or @reference.match_type == "partial"
    do_search
    @page_title = "Search: no results for '#{@query}'" if @search.results_size and @search.results_size < 1
    @timeline = search_timeline(@search)
    haml(:search)
  end
end

def get_search_params params
  options = {}
  sort_options = ['date', 'reverse_date']
  param_keys = [:query, :speaker, :century, :decade, :year, :month, :day, :sort, :type, :all_speaker_filters]
  param_keys.each{ |key| options[key] = params[key] }
  options[:page] = params[:page].to_i if !params[:page].blank?
  options[:century] = nil unless /C\d\d/.match options[:century]
  options[:decade] = nil unless /\d\d\d\ds/.match options[:decade]
  options[:year] = nil unless /\d\d\d\d/.match options[:year]
  options[:month] = nil unless /\d\d\d\d-\d\d?/.match options[:month]
  options[:day] = nil unless /\d\d\d\d-\d\d?-\d\d?/.match options[:day]
  options[:sort] = nil unless sort_options.include? options[:sort]
  return options
end

def get_search_results
  success = false
  begin
    @search.get_results
    success = true
  rescue SearchException => e
    RAILS_DEFAULT_LOGGER.error "Solr error: #{e.to_s}"
  end
  return success
end

def do_search
  options = get_search_params(params)
  
  @query = CGI::unescape(params[:query])
  @query = Sanitize.clean(@query)
    
  if @query
    @page_title = "Search: #{@query}"
    @search = Search.new(options)
    success = get_search_results
  end
end