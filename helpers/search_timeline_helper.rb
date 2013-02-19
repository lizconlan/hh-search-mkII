# adapted from:
#  https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/present_on_date/lib/present_on_date_timeline_helper.rb
#  https://github.com/millbanksystems/hansard/blob/master/app/helpers/search_helper.rb
#  https://github.com/millbanksystems/hansard/blob/master/app/helpers/application_helper.rb

module SearchTimelineHelper
  def month_abbr(month)
    Date::ABBR_MONTHNAMES[month].downcase
  end
  
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
  
  def timeline_link(label, interval, resolution, html_options={})
    resolution = "century" if resolution.nil?
    option_attribs = ""
    unless html_options.empty?
      html_options.keys.each do |attrib|
        option_attribs = %Q|#{option_attribs} #{attrib}="#{html_options[attrib]}"|
      end
    end
    %|<a href="#{timeline_url(interval, resolution)}" title="Results for '#{@query}' #{interval_suffix(resolution, label, interval)}"#{option_attribs}>#{label}</a>|
  end
  
  def timeline_url(interval, resolution=nil)
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
    if name
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
  
  # dates index
  # on decade   -> show 100 years in decades
  # on year     -> show 10 years  (lets you jump years)
  # on month    -> show 12 months (lets you jump months)
  # on date     -> show days in month (lets you jump days)
  def timeline(date, resolution=nil, options={})
    RAILS_DEFAULT_LOGGER.info 'in timeline function'
    options[:first_of_month] = true unless defined? options[:first_of_month]
    start_date, end_date = date.get_interval_delimiters resolution, options
    if block_given?
      day_counts = yield([start_date, end_date])
    else
      day_counts = start_date.material_dates_count_upto(end_date)
    end
    RAILS_DEFAULT_LOGGER.info 'got dates and counts for timeline'
    intervals = get_intervals date, day_counts, resolution, options
    intervals = scale intervals
    timeline_html = timeline_html date, intervals, resolution, options
    RAILS_DEFAULT_LOGGER.info 'returning from timeline function'
    timeline_html
  end
  
  def interval_key day, resolution
    case resolution
    when :day;   day
    when :month; day.year.to_s + '_' + day.month.to_s
    when :year;  day.year
    when :decade; day.decade_string 
    else; day.century_string   
    end
  end
  
  def link_for interval, resolution, counts, options
    label = label_for interval, resolution
    if counts.sum > 0
      timeline_link(label, interval, resolution, {})
    else
      label
    end
  end
  
  private
    
    def scale intervals
      max = 0
      intervals.each do |interval|
        buckets = interval[1]
        buckets.each_index do |i|
          if buckets[i] != 0
            max = buckets[i] if (buckets[i] > max)
          end
        end
      end
      
      divider = max / 40.0
      
      intervals.each do |interval|
        buckets = interval[1]
        buckets.each_index do |i|
          if buckets[i] != 0
            buckets[i] = (buckets[i] / divider).round
            buckets[i] = 1 if buckets[i] == 0
          end
        end
      end
      
      intervals
    end
    
    def get_intervals date, day_counts, resolution, options
      intervals = seed_intervals date, resolution, options
      first, last = date.get_interval_delimiters(resolution, options)
      size = bucket_size resolution
      day_counts.each do |day, count|
        if day <= last and day >= first
          key = interval_key day, resolution
          index = bucket_index day, resolution
          begin
            intervals[key][index] += count
          rescue Exception => e
            raise e.to_s + ' ' + index.to_s
          end
        end
      end
      intervals = sort_intervals(resolution, intervals)
    end
    
    def sort_intervals resolution, intervals
      if resolution == :month
        intervals = intervals.sort_by{|key, val| key.split('_')[1].to_i}
      else
        intervals = intervals.sort
      end
      intervals
    end
    
    def seed_intervals date, resolution, options
      intervals = {}
      stepsize = 1
      first, last = date.get_interval_delimiters(resolution, options)
      stepsize = 365 if [:year, :decade].include? resolution
      size = bucket_size resolution
      first.step(last, stepsize) do |d|
        key = interval_key d, resolution
        intervals[key] = Array.new(size) {|i| 0} unless intervals[key]
      end
      intervals
    end
    
    def bucket_index day, resolution
      case resolution
      when :day;   0
      when :month; (day.day / 5) < 6 ? (day.day / 5) : 5
      when :decade; (day.year.to_s.last.to_i) / 2
      else         (day.month - 1) / 2
      end
    end
    
    def bucket_size resolution
      case resolution
      when :day;    1
      when :month;  6
      when :decade; 5
      else          6
      end
    end
    
    def label_for interval, resolution
      case resolution
      when :day
        day = interval.day
        label = (day == '1') ? month.capitalize + ' ' + day : day
      when :month
        month = interval.split('_')[1]
        month = Date::ABBR_MONTHNAMES[month.to_i].capitalize
        label = month
      when :year
        label = interval.to_s
      when :decade
        label = interval.to_s
      else
        label = "#{interval[1..2].to_i.ordinalize} century"
      end
      label
    end
    
    def year_from_interval interval
      interval.split('_')[0]
    end
    
    def month_from_interval interval
      month = interval.split('_')[1]
      Date::ABBR_MONTHNAMES[month.to_i].capitalize
    end
    
    def date_css interval, resolution
      'timeline_date'
    end
    
    def block_css interval, resolution
      'timeline_block'
    end
    
    def lower_resolution_link(date, resolution, options)
      return '' unless resolution
      lower_resolution = Date.lower_resolution(resolution)
      options[:default_label] = options[:top_label]
      interval, label = nav_link_label_and_interval(date, lower_resolution, options)
      nav_link(label, interval, lower_resolution, options, :rel => "up")
    end
    
    def next_link(date, higher_res, resolution, options)
      start_date, end_date = date.get_interval_delimiters higher_res, options
      end_date += 1
      options[:default_label] = "&gt;&gt;"
      interval, label = nav_link_label_and_interval(end_date, resolution, options)
      if options[:upper_nav_limit] and end_date > options[:upper_nav_limit]
        label
      else
        nav_link(label, interval, resolution, options, :rel => "next nofollow")
      end
    end
    
    def previous_link(date, higher_res, resolution, options)
      start_date, end_date = date.get_interval_delimiters higher_res, options
      start_date -= 1
      options[:default_label] = "&lt;&lt;"
      interval, label = nav_link_label_and_interval(start_date, resolution, options)
      if options[:lower_nav_limit] and start_date < options[:lower_nav_limit]
        label
      else
        nav_link(label, interval, resolution, options, :rel => "prev nofollow")
      end
    end
    
    def nav_link_label_and_interval(date, resolution, options)
      interval = interval_key(date, resolution)
      label = label_for(interval, resolution) || options[:default_label]
      [interval, label]
    end
    
    def nav_link(label, interval, resolution, options, html_options)
      timeline_link(label, interval, resolution, html_options)
    end
    
    def timeline_label(date, intervals, resolution, options)
      if intervals.empty?
        interval = ''
      else
        interval = intervals.first[0]
      end 
      label = case resolution
      when :decade
        "#{Date.new(interval.to_i).century_ordinal} century"
      when :year
        date.decade_string
      when :month
        year_from_interval interval
      when :day
        "#{Date::ABBR_MONTHNAMES[interval.month]} #{interval.year}"
      else
        ''
      end
      label
    end
    
    def timeline_html date, intervals, resolution, options
      next_link = ''
      previous_link = ''
      current_page_resolution = Date.lower_resolution(resolution)
      
      if options[:navigation] 
        up_link = lower_resolution_link(date, current_page_resolution, options)
        previous_link = previous_link(date, resolution, current_page_resolution, options)
        next_link = next_link(date, resolution, current_page_resolution, options)
      end
      
      timeline = %Q[<table class="timeline">
  <tbody class="timeline-body">]
      timeline += %Q[
    <tr class="timeline-header-row">
      <td colspan="#{intervals.size+2}" align="center" class="timeline_header">
        #{up_link}
      </td>
    </tr>]
      timeline += %Q[
    <tr class="timeline-navigation-row">
      <td align="center" class="timeline_nav">
      #{previous_link}
      </td>]
      
      intervals.each do |interval, counts|
        if counts.sum > 0
          onclick = "onclick=\"location.href='#{timeline_url(interval, resolution)}'\""
          link_start = "<a href=\"#{timeline_url(interval, resolution)}\">"
          link_end = '</a>'
        else
          onclick = ''
          link_start = ''
          link_end = ''
        end
        timeline += %Q[
      <td class="#{block_css interval, resolution}" nowrap="nowrap" valign="bottom" #{onclick}>
        #{link_start}]
        
        counts.each do |count|
          if count > 0
            timeline += %|<img src="images/dot.gif" class="timeline_bar" alt="" width="5" height="#{count.round.to_s}"/>|
          end
        end
        timeline += %Q[
        #{link_end}
      </td>]
      end
      
      timeline += %Q[
      <td class="timeline_nav">
      #{next_link}
      </td>
    </tr>
    <tr class="timeline-caption-row">
      <td>
      </td>]
      
      intervals.each do |interval, counts|
        timeline += %Q[
      <td class="#{date_css interval, resolution}" valign="top">#{link_for interval, resolution, counts, options }</td>]
      end
      
      timeline += %Q[
      <td>
      </td>
    </tr>
    <tr class="timeline-summary-row">
      <td colspan="#{intervals.size+2}" align="center" class="timeline_title">]
      timeline += timeline_label(date, intervals, resolution, options)
      timeline += %Q[
      </td>
    </tr>
  </tbody>
  </table>]
      timeline
    end
end