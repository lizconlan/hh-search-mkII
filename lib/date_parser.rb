class DateParser

  def self.date_match query
    if query
      match = nil
      if month_and_year_match = parse_month_and_year(query)
        match = month_and_year_match
      elsif year_match = parse_year(query)
        match = year_match
      elsif date_match = parse_complete_date(query)
        match = date_match
      end
      return nil unless match
      return nil if date_in_future? match
      return nil if Sitting.find_in_resolution(date_from_params(match), match[:resolution]).empty?
      return match
    end
  end

  def self.parse_complete_date(query)
    date_match = nil
    begin
      date = Date.parse(query)
      date_match = { :year => date.year,
                     :month => Date::ABBR_MONTHNAMES[date.month].downcase,
                     :day => date.day,
                     :resolution => :day }
    rescue
    end
    date_match
  end

  def self.date_from_params(date_match)
    year = date_match[:year]
    month = (months_to_nums[date_match[:month]] or 1)
    day = (date_match[:day] or 1)
    Date.new(year, month, day)
  end

  def self.date_in_future?(date_match)
    return unless date_match
    return true if date_from_params(date_match) > Date.today
  end

  def self.months_to_nums
    month_strings = {}
    abbr_months = Array.new(Date::ABBR_MONTHNAMES)
    months = Array.new(Date::MONTHNAMES)
    [abbr_months, months].each do |monthlist|
      monthlist.each_with_index do |month, index|
        month = month.downcase if month
        month_strings[month] = index
      end
    end
    month_strings.delete(nil)
    month_strings
  end

  MONTH_TO_NUMS = DateParser::months_to_nums
  MONTH_YEAR_PATTERN = Regexp.new('^(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|september|oct|october|nov|november|dec|december) ((18|19|20)\d\d)\.?$','i')

  def self.parse_month_and_year(query)
    date_match = nil
    if match = MONTH_YEAR_PATTERN.match(query)
      month = MONTH_TO_NUMS[match[1].downcase]
      date_match = { :year => match[2].to_i,
                     :month => Date::ABBR_MONTHNAMES[month].downcase,
                     :resolution => :month }
    end
    date_match
  end

  YEAR_PATTERN = Regexp.new('^((18|19|20)\d\d)\.?$')

  def self.parse_year(query)
    date_match = nil
    if match = YEAR_PATTERN.match(query)
      date_match = { :year => match[1].to_i,
                     :resolution => :year }
    end
    date_match
  end
  
end
