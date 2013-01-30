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
    return if (resolution.nil?) or (search.date_facets.empty? and !search.date_filter?)
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
    %|<a href="#{querystring_builder(resolution => interval.to_s.gsub("_", "-"))}" title="Results for '#{@query}' #{interval_suffix(resolution, label, interval)}">#{label}</a>|
  end

  def timeline_url(interval, options, resolution)
    link_params = params_without_date_and_page_filters(resolution)
    resolution = "century" if resolution.nil?
    %|<a href="#{querystring_builder(resolution => interval.to_s.gsub("_", "-"))}">#{label}</a>|
  end
  
  def atom_url
    url_for(params.merge(:format => 'atom'))
  end
  
  def add_date_filter(params, resolution, interval) 
    if resolution and interval
      params[resolution] = interval.to_s.sub('_','-') 
    elsif interval
      params[:century] = interval
    end
  end
    
  def params_without_date_and_page_filters(resolution)
    higher_resolution = Date.higher_resolution(resolution)
    lower_resolution = Date.lower_resolution(resolution)
    params_without(['page', higher_resolution, lower_resolution, :century])
  end
  
  def interval_suffix(resolution, label, interval)
    case resolution
      when nil
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

  def speaker_links(speakers)
    speakers.collect {|speaker| speaker_link(speaker)}.join(', ')
  end
  
  def speaker_link(speaker)
     link_to speaker.name, person_url(speaker), :class => "speaker-match"
  end
  
  def sort_links(current_sort, params)
    sort_links = []
    sort_params = params_without('page')
    sort_links << sort_link(current_sort, 'reverse_date', "Sort by MOST RECENT", sort_params)
    sort_links << sort_link(current_sort, 'date', "Sort by EARLIEST", sort_params)
    sort_links << sort_link(current_sort, nil, "Sort by MOST RELEVANT", sort_params)
    sort_links.join(' | ')
  end
  
  def sort_link(current_sort, sort, text, params)
    link_to_unless(current_sort == sort, text, params.merge(:sort => sort))
  end

  def hit_fragment(contribution, search)
    fragment = ''
    if search.highlights[contribution.id]
      fragment = search.highlights[contribution.id].join(" &hellip; ")
      fragment = format_result_fragment(fragment, search)
    end
    fragment
  end

  def format_result_fragment(fragment, search)
    fragment = fragment.gsub('&amp;', '&')
    leading_punctuation = [/\A(\/|\\|;|\.|,|\(|\)|:)/, '']
    broken_entities = [/\A(#x[\dA-Z]{2,4};)/, '']
    contribution_pattern = /(contribut(.){0,4})/i
    problems = [leading_punctuation, broken_entities]
    unless contribution_pattern.match(search.query)
      prefix = Regexp.escape(search.highlight_prefix || '')
      suffix = Regexp.escape(search.highlight_suffix || '')
      problems << contribution_highlighted = [/#{prefix}#{contribution_pattern}#{suffix}/i, '\1']
    end
    problems.each do |problem, replacement|
      fragment.gsub!(problem, replacement)
    end
    fragment
  end

  def hit_section_link section
    link_text = section.title || section.sitting.title
    url = section_url(section)
    link_to link_text, url
  end

  def sitting_type_facet_link(type, query, text=nil)
    link_text = text || type
    link_to(link_text, sitting_type_facet_url(type, query), {:title=>"Show only results from #{type}"})
  end

  def sitting_type_facet_url(type, query)
    params.merge(:type => type, :query => query, :page => nil)
  end

  def speaker_facet_link(speaker, name, query, options = {})
    options[:show_times] = true if options[:show_times].nil?
    name_to_use = name || speaker.name
    link_text = name_to_use 
    if options[:show_times] && options[:times] > 1
      link_text += " <span class='facet_times'>(#{options[:times]})</span>"
    end
    link_text +=options[:end_char] if options[:end_char]
    link_to link_text, params.merge(:speaker => speaker.slug, :query => query, :page => nil), {:title=>"Show only results from #{name_to_use}"}
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
  
  def search_results_summary(search)
    text = ''

      if search.results_size <= search.num_per_page
        text += "<h3>#{pluralize(search.results_size, 'result')}</h3>"
      else
        start = search.first_result
        finish = search.last_result
        text += "<h3 id='results-header'>Results #{number_with_delimiter(start)} to #{number_with_delimiter(finish)} of #{number_with_delimiter(search.results_size)}</h3>"
      end
    text
  end
  
  def first_results_url
    #url_for(params.merge(:only_path => false, :page => 1))
    "first!"
  end
  
  def next_results_url(paginator)
    #url_for(params.merge(:only_path => false, :page => paginator.next_page))
    "next!"
  end
  
  def previous_results_url(paginator)
    #url_for(params.merge(:only_path => false, :page => paginator.previous_page))
    "prev!"
  end
  
  def last_results_url(paginator)
    #url_for(params.merge(:only_path => false, :page => paginator.total_pages))
    "last!"
  end
  
  def atom_link(builder, rel, href)
    builder.link(:rel => rel, :href => href, :type => 'application/atom+xml')
  end

end