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
    %|<a href="#{querystring_builder(resolution => interval.to_s.gsub("_", "-"))}" title="Results for '#{@query}' #{interval_suffix(resolution, label, interval)}"#{option_attribs}>#{label}</a>|
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
      filter_text = filter.name
      param = "speaker"
    else
      filter_text = filter
      param = 'type'
    end
    return [filter_text, param]
  end
end