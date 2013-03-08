require 'sinatra'
require 'sinatra/config_file'
require 'haml'
require 'active_record'
require './lib/active_record_monkeypatch.rb'
require 'sanitize'
require 'date'
require 'logger'
require './lib/date_extension.rb'
require './helpers/search_timeline_helper.rb'

error 404 do
  @page_title = "Page not found"
  haml(:"404")
end

error 500 do
  haml(:"500", :layout => false)
end

require 'newrelic_rpm'

set :logging, true

config_file './config/config.yml'

@logger = Logger.new('log/app.log')

WEBSOLR_URL = "http://127.0.0.1:8983/solr"
PARENT_URL = settings.parent_url
RAILS_ROOT = File.dirname(__FILE__)
RAILS_DEFAULT_LOGGER = @logger

LAST_DATE = Date.new(2005, 12, 31)
FIRST_DATE = Date.new(1803, 1, 1)
DEFAULT_FEEDS = [10, 100, 200]

dbconfig = YAML::load(File.open 'config/database.yml')
ActiveRecord::Base.establish_connection(dbconfig)

helpers do
  include SearchTimelineHelper
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
  query = CGI::escape(Sanitize.clean(params[:query].gsub("+", "%2B")))
  qs = querystring_builder({:page => 1})
  qs = qs[settings.search_redir.length+1..qs.length]
  query = "#{query}?#{qs}" unless qs.blank? or !qs.include?("=")
  redirect "#{settings.search_redir}/#{query}"
end

get "/:query" do
  @reference = HansardReference.lookup(CGI::unescape(params[:query]))
  @query = Sanitize.clean(CGI::unescape(params[:query])).gsub("%2B","+").strip
  if @reference
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
  
  @query = CGI::unescape(params[:query]).gsub("%2B","+")
  @query = Sanitize.clean(@query)
  
  if @query
    @page_title = "Search: #{@query}"
    @search = Search.new(options)
    success = get_search_results
  end
end