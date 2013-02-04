# adapted from: https://github.com/millbanksystems/hansard/blob/master/app/helpers/search_helper.rb

require './helpers/present_on_date_timeline_helper'

module SearchHelper
  
  include PresentOnDateTimelineHelper
  
  def month_string date, options={}
    options[:brief] ? "#{month_abbr(date.month).titleize}." : Date::MONTHNAMES[date.month]
  end

  def format_date(date, resolution, options={})
    case resolution
      when :decade
        "#{date.decade_string}"
      when :year
        "#{date.year}"
      when :month
        "#{month_string(date,options)} #{date.year}"
      when :day
        "#{date.day} #{month_string(date,options)} #{date.year}"
      else
        "#{date.century_ordinal} century"
    end
  end
  
  def search_timeline(search)
    resolution = Date.higher_resolution(search.resolution)
    return if (resolution.nil?) or (search.date_facets.nil?) or (search.date_facets.empty? and !search.date_filter?)
    options = timeline_options(resolution, "").merge(:top_label => "Results by decade")
    timeline = timeline(timeline_date(search), resolution, options) do |start_date, end_date|
      search.date_facets
    end
    timeline
  end
  
  def timeline_date(search)
    search.timeline_anchor or search.start_date
  end
  
  def timeline_link(label, interval, options, resolution, html_options={})
    resolution = "century" if resolution.nil?
    option_attribs = ""
    unless html_options.empty?
      html_options.keys.each do |attrib|
        option_attribs = %Q|#{option_attribs} #{attrib}="#{html_options[attrib]}"|
      end
    end
    %|<a href="#{timeline_url(interval, options, resolution)}" title="Results for '#{@query}' #{interval_suffix(resolution, label, interval)}"#{option_attribs}>#{label}</a>|
  end
  
  def timeline_url(interval, options, resolution)
    resolution = "century" if resolution.nil?
    querystring_builder(resolution => interval.to_s.gsub("_", "-"))
  end
  
  def interval_suffix(resolution, label, interval)
    case resolution
      when nil, "century"
        ": #{label}"
      when :decade
        "in the #{label}" 
      when :year
        "in #{label}"
      when :month 
        "in #{label}"
      when :day
        "on #{interval.to_s(:long)}"
      else 
        ''
    end
  end

  def show_filter(filter, search)
    filter_text = ''
    param = nil
    if filter.is_a? Date
      filter_text = format_date(filter, search.resolution)
      param = search.resolution.to_s
    elsif filter.is_a? Person
      filter_text = "#{filter.honorific} #{filter.name}"
      param = "speaker"
    else
      filter_text = filter
      param = 'type'
    end
    return [filter_text, param]
  end
  
  def timeline_options(resolution, sitting_type)
    options = { :upper_nav_limit => LAST_DATE,
                :lower_nav_limit => FIRST_DATE,
                :first_of_month => false,
                :navigation => true,
                :sitting_type => sitting_type }
    options
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
end