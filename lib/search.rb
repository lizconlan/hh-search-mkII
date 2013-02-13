# adapted from: https://github.com/millbanksystems/hansard/blob/master/app/models/search.rb

require 'sanitize'

class SearchException < Exception
end

class Search
  attr_accessor :sort, :page, :num_per_page, :last_page, :hansard_reference
  attr_accessor :query, :search_string
  attr_accessor :start_date, :end_date, :resolution, :date_match, :date_facets, :timeline_anchor
  attr_accessor :sitting_type, :sitting_type_facets
  attr_accessor :results_size, :highlights, :results
  attr_accessor :display_speaker_facets, :display_all_speakers, :speakers_to_display, :speaker_facets
  attr_accessor :speaker, :speaker_matches
  
  def initialize(options)
    self.start_date = FIRST_DATE
    parse_options(options)
    date_value = time_interval(options)
    set_interval(date_value) if date_value
    create_search_string
    find_matches
  end
  
  def clean_query query
    query = Sanitize.clean(query)
    query.gsub!(/(^[^"]*)(")([^"]*)$/, '\1\3')
    return query
  end
  
  def parse_options(options)
    self.sort = options[:sort]
    self.page = options[:page] || 1
    self.num_per_page = options[:num_per_page] || 10
    self.speakers_to_display = options[:speakers_to_display] || 5
    self.query = clean_query(options[:query])
    self.sitting_type = options[:type]
    self.speaker = Person.find_by_slug(options[:speaker]) if options[:speaker]
    self.display_all_speakers = options[:all_speaker_filters]
  end
  
  def find_matches
    self.speaker_matches = Person.find_partial_matches(query, limit=5)
    self.date_match = DateParser.date_match(query)
  end
  
  def create_search_string
    self.search_string = text_search
    self.search_string += speech_search if speaker
    self.search_string += type_search if sitting_type
    self.search_string += interval_query_search if resolution
  end
  
  def text_search
    "solr_text:#{query}"
  end

  def type_search
    " AND sitting_type:\"#{sitting_type}\""
  end
  
  def speech_search
    " AND person_id:\"#{speaker.id}\""
  end
  
  def interval_query_search
    " AND date:[#{start_date} TO #{end_date}]"
  end
  
  def time_interval(options)
    [:century, :decade, :year, :month, :day].each do |interval|
      if options[interval]
        self.resolution = interval
        return options[interval]
      end
    end
  end
  
  def set_interval(value)
    case self.resolution
    when :century
      self.start_date, self.end_date = century_start_end(value)
    when :decade
      self.start_date, self.end_date = decade_start_end(value)
    when :year
      self.start_date, self.end_date = year_start_end(value)
    when :month
      self.start_date, self.end_date = month_start_end(value)
    when :day
      self.start_date = self.end_date = Date.parse(value)
    end
  end
  
  def search_options
    options = pagination_options.merge(highlight_options)
    options = options.merge(facet_options)
    options = options.merge(sort_options) if sort
    options
  end
  
  def pagination_options
    { :offset => offset,
      :limit  => num_per_page }
  end
  
  def highlight_options
    { :highlight => { :fields =>["solr_text"],
                      :prefix => highlight_prefix,
                      :suffix => highlight_suffix,
                      :require_field_match => false,
                      :fragsize => 200 } }
  end
  
  def highlight_prefix
    "<em>"
  end
  
  def highlight_suffix
    "</em>"
  end
  
  def sort_options
    case sort
    when 'date'
     { :order => 'date asc' }
    when 'reverse_date'
     { :order => 'date desc'}
    else
      {}
    end
  end
  
  def facet_options
    { :facets => { :fields => [:person_id, :date, :sitting_type],
                   :zeros => false } }
  end
  
  def century_start_end(century)
    start_year = Date.year_from_century_string(century)
    date = Date.new(start_year)
    date.first_and_last_of_century
  end
  
  def decade_start_end(decade)
    start_year = decade.to_i
    return Date.new(start_year,1,1), Date.new(start_year+9,12,31)
  end
  
  def year_start_end(year)
    year = year.to_i
    return Date.new(year,1,1), Date.new(year,12,31)
  end
  
  def month_start_end(year_month)
    year = year_month.split('-')[0].to_i
    month = year_month.split('-')[1].to_i
    start_date = Date.new(year,month,1)
    return start_date, start_date.end_of_month
  end
  
  def get_results
    @results ||= get_query_results
  end
  
  def filters
    filters = []
    filters << speaker if speaker
    filters << sitting_type if sitting_type
    filters << start_date if date_filter?
    filters
  end
  
  def date_filter?
    (start_date and resolution) ? true : false
  end
  
  def any_facets?
    (display_speaker_facets.to_a.size > 1 or sitting_type_facets.to_a.size > 1)
  end
  
  def offset
    (page - 1) * num_per_page
  end
  
  def first_result
    offset + 1
  end
  
  def last_result
    last = first_result + (num_per_page - 1)
    last = results_size if last > results_size
    last
  end
  
  def last_page
    last_page = results_size.to_f / num_per_page.to_f
    last_page = last_page.to_i < last_page ? last_page.to_i + 1 : last_page.to_i
    last_page
  end
  
  protected
    
    def get_query_results
      RAILS_DEFAULT_LOGGER.info 'getting result set'
      begin
        RAILS_DEFAULT_LOGGER.info "search: '#{search_string}', options: #{search_options}"
        result_set = Contribution.find_by_solr(search_string, search_options)
      rescue Exception => e
        raise SearchException, e.to_s
      end
      RAILS_DEFAULT_LOGGER.info 'got result set'
      self.results_size = result_set.total_hits
      RAILS_DEFAULT_LOGGER.info 'getting highlights'
      self.highlights = query_highlights(result_set)
      RAILS_DEFAULT_LOGGER.info 'got highlights'
      self.speaker_facets = create_speaker_facets(result_set)
      if display_all_speakers
        self.display_speaker_facets = speaker_facets
      else
        self.display_speaker_facets = speaker_facets.slice(0, speakers_to_display)
      end
      self.date_facets = create_date_facets(result_set)
      self.sitting_type_facets = create_sitting_type_facets(result_set)
      result_set.results
    end
    
    def get_facets(result_set, facet_name)
      return result_set.facets["facet_fields"][facet_name] if result_set.facets &&
      !result_set.facets["facet_fields"].nil? &&
      !result_set.facets["facet_fields"].empty? &&
      !result_set.facets["facet_fields"][facet_name].nil? &&
      !result_set.facets["facet_fields"][facet_name].empty?
      return nil
    end
    
    def create_date_facets(result_set)
      RAILS_DEFAULT_LOGGER.info 'create_date_facets start'
      date_facets = get_facets(result_set, "date_facet")
      return {} unless date_facets
      facet_hash = {}
      highest_count = 0
      century_hash = Hash.new(0)
      date_facets.each do |date, count|
        date = Date.strptime(date)
        facet_hash[date] = count
        century_hash[date.century] += count
      end
      
      unless (century_hash.empty? or resolution)
        most_common_century = century_hash.sort{|a,b| b[1]<=>a[1]}.first.first
        self.timeline_anchor = Date.first_of_century(most_common_century)
      end
      RAILS_DEFAULT_LOGGER.info 'create_date_facets end'
      return facet_hash
    end
    
    def create_speaker_facets(result_set)
      RAILS_DEFAULT_LOGGER.info 'create_speaker_facets start'
      speaker_facets = get_facets(result_set, "person_id_facet")
      return [] unless speaker_facets
      speaker_facets = speaker_facets.select{ |speaker, count| count > 1 }
      speaker_facets = speaker_facets.sort{ |a,b| b[1] <=> a[1] }
      display_count = display_all_speakers ? speaker_facets.size : speakers_to_display
      display_speaker_ids = speaker_facets[0...display_count].map{ |item| item[0] }
      speakers = Person.find(display_speaker_ids)
      display_speaker_hash = Hash[*speakers.map{|speaker| [speaker.id, speaker]}.flatten]
      speaker_facets[0...display_count].each{ |item| item[0] = display_speaker_hash[item[0].to_i] }
      RAILS_DEFAULT_LOGGER.info 'create_speaker_facets end'
      speaker_facets
    end
    
    def create_sitting_type_facets(result_set)
      RAILS_DEFAULT_LOGGER.info 'create_sitting_type_facets start'
      sitting_type_facets = get_facets(result_set, "sitting_type_facet")
      return [] unless sitting_type_facets
      sitting_type_facets = sort_by_reverse_value(sitting_type_facets)
      sitting_type_facets = sitting_type_facets.sort do |a,b|
        [b[1], a[0]] <=> [a[1], b[0]]
      end.collect
      RAILS_DEFAULT_LOGGER.info 'create_sitting_type_facets end'
      return sitting_type_facets
    end
    
    def query_highlights(result_set)
      highlights = {}
      begin
        return highlights unless result_set.highlights
        result_set.highlights.each_pair{ |id, value| highlights[id] = value["solr"]}
        return highlights
      rescue
        return {}
      end
    end
    
    def sort_by_reverse_value(hash)
      # sorts by score from high to low
      array = hash.to_a
      array = array.sort{ |a,b| [b[1]] <=> [a[1]] }.collect
    end
end