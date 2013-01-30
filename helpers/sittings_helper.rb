module SittingsHelper
  def sitting_timeline(date, resolution, sitting_type)
    options = timeline_options(resolution, sitting_type).merge(:top_label => "Sittings by decade")
    timeline(date, resolution, options) do |start_date, end_date|
      sitting_type.counts_in_interval(start_date, end_date)
    end
  end

  def timeline_url(interval, options, resolution)
    date_options =  date_params(interval, options, resolution)
    date_options.update(:sitting_type => options[:sitting_type]) if options[:sitting_type]
    on_date_url(date_options)
  end

  def timeline_link(label, interval, options, resolution, html_options)
    link_to(label, timeline_url(interval, options, resolution), html_options)
  end
  
  def link_to_section_years_ago(years)
    section = Sitting.section_from_years_ago(years)
    return '' unless section
    link_to(section.title_via_associations, section_url(section), :title => "Content from Hansard on the date nearest to " + years.to_s + " years ago")
  end
  
end