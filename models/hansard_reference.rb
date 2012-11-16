# encoding: utf-8

require './models/section'

class HansardReference
  attr_reader :house, :date, :column, :end_column, :url, :match_type, :sitting_type, :volume
  
  MONTHS = Date::MONTHNAMES[1..12]
  SHORT_MONTHS = Date::ABBR_MONTHNAMES[1..12]
  
  REFERENCE_PATTERN = /H(C|L) Deb\s+.+$/i
  ALT_REFERENCE_PATTERN = /^Deb\s+.+$/i
  
  DATE_PATTERN = /(?:\s|\A)(\d\d?)\s+(#{MONTHS.join('|')}|#{SHORT_MONTHS.join('|')}|Sept)\s+(\d\d\d\d)/i
  
  VOLUME_PATTERN = /vol\s*(\d+)/i
  ALT_VOLUME_PATTERN = /^(\d+)\sH(L|C)/
  
  COLUMN_PATTERN = /c\.?(?:olumns? )?(\d+)(\s*(-|–)\s*(\d+))?/i
  
  SERIES_PATTERN = /\((\S+)\s+series\)/i
  
  WRITTEN_STATEMENT_PATTERN = /\d\s*WS/i
  
  WRITTEN_ANSWER_PATTERN = /\d\s*W/i
  
  WESTMINSTER_HALL_PATTERN = /\d\s*WH/i
  
  GRAND_COMMITTEE_PATTERN = /\d\s*GC/i
  
  COLUMN_NUMBER_PATTERN = / (c?c) (\d)/

  def self.lookup(text)
    house = date = column = end_column = sitting_type = volume = nil
    url = ""
    text = text.tr('.,','')
    unless REFERENCE_PATTERN.match(text)
      if ALT_REFERENCE_PATTERN.match(text)
        #assume it's a Lords Report
        house = "Lords"
        sitting_type = "Lords reports"
      else
        return false
      end
    end
    
    house = self.find_house(text) unless house
    return false unless house
    
    date = self.find_date(text)
    return false unless date.is_a?(Date)
    
    if match = VOLUME_PATTERN.match(text)
      volume = match[1]
    end
    
    if COLUMN_NUMBER_PATTERN.match(text)
      column, end_column = self.find_columns(text)
    elsif COLUMN_PATTERN.match(text)
      column, end_column = self.find_columns(text)
    else
      url = "/sittings/#{date.year}/#{SHORT_MONTHS[date.month-1].downcase}/#{date.day}"
      if Section.where(:date => date).limit(1).empty?
        return HansardReference.new({:match_type => "not stored", :date => date, :volume => volume, :house => house})
      else
        return HansardReference.new({:url => url, :match_type => "partial", :date => date, :volume => volume, :house => house})
      end
    end
    
    if WRITTEN_STATEMENT_PATTERN.match(text)
      sitting_type = "Written Statements"
    elsif WESTMINSTER_HALL_PATTERN.match(text)
      sitting_type = "Westminster Hall"
    elsif WRITTEN_ANSWER_PATTERN.match(text)
      sitting_type = "Written Answers"
    elsif GRAND_COMMITTEE_PATTERN.match(text)
      sitting_type = "Grand Committee report"
    else
      sitting_type = nil unless sitting_type == "Lords reports"
    end
    
    if sitting_type
      sitting = self.get_db_sitting_type(sitting_type, house)
      ref = find_matching_section(date, sitting, column, end_column)
    else
      sitting = self.get_db_sitting_type("no match", house)
      ref = find_matching_section(date, sitting, column, end_column)
      sitting_type = sitting_type_from_db_sitting_type(sitting)
    end
    
    if ref
      url = construct_url(house, date, ref.slug, column, sitting_type)
      HansardReference.new({:sitting_type => sitting_type, :match_type => "full", :url => url, :house => house, :date => date, :volume => volume, :column => column_with_suffix(house, column, sitting_type)})
    else
      if Section.where(:date => date).limit(1).empty?
        return HansardReference.new({:sitting_type => sitting_type, :match_type => "not stored",  :house => house, :date => date, :volume => volume, :column => column_with_suffix(house, column, sitting_type)})
      else
        return false
      end
    end
  end
  
  def initialize(attributes)
    @url = attributes[:url] if attributes[:url]
    @match_type = attributes[:match_type] if attributes[:match_type]
    @sitting_type = attributes[:sitting_type] if attributes[:sitting_type]
    @house = attributes[:house] if attributes[:house]
    @date = attributes[:date] if attributes[:date]
    @volume = attributes[:volume] if attributes[:volume]
    @column = attributes[:column] if attributes[:column]
  end
  
  def year
    @date.year
  end
  
  def date_to_s
    @date.day.to_s + ' ' + MONTHS[@date.month - 1] + ' ' + @date.year.to_s
  end
  
  
  private
    
    def self.construct_url(house, date, slug, start_column, sitting_type)
      url_date = "#{date.year}/#{SHORT_MONTHS[date.month-1].downcase}/#{date.day.to_s.rjust(2, "0")}"
      case sitting_type
      when "Commons sitting", "Lords sitting"
        "/#{house.downcase()}/#{url_date}/#{slug}#column_#{column_with_suffix(house, start_column, sitting_type)}"
      else
        "/#{sitting_type.downcase.gsub(" ", "_")}/#{url_date}/#{slug}#column_#{column_with_suffix(house, start_column, sitting_type)}"
      end
    end
    
    def self.column_with_suffix(house, column, sitting_type)
      case sitting_type
      when /sitting/, "Lords reports"
        column
      when "Written Answers"
        if house == "Commons"
          "#{column}w"
        else
          "#{column}wa"
        end
      when "Grand Committee report"
        "#{column}gc"
      when "Westminster Hall"
        "#{column}wh"
      when "Written Statements"
        "#{column}ws"
      end
    end
    
    def self.find_columns text
      start_column = end_column = nil
      
      if match = COLUMN_PATTERN.match(text)
        start_text = match[1]
        start_column = start_text.to_i
        end_text = match[4]
        
        if end_text
          end_number = end_text.to_i
          number_represents_significant_digits = (end_number < start_column)
          
          if number_represents_significant_digits
            placeholder = ''
            end_text.size.times {|i| placeholder += '0'}
            base_number = (start_text[0, start_text.length - end_text.size] + placeholder)
            end_column = base_number.to_i + end_number
          else
            end_column = end_number
          end
        end
      end
      return start_column, end_column
    end
    
    def self.get_db_sitting_type(type, house)
      case type
      when "Written Answers"
        "#{house}WrittenAnswersSitting"
      when "Westminster Hall"
        "WestminsterHallSitting"
      when "Written Statements"
        "#{house}WrittenStatementsSitting"
      when "Grand Committee report"
        "GrandCommitteeReportSitting"
      when "Lords reports"
        "HouseOfLordsReport"
      else
        "HouseOf#{house}Sitting"
      end
    end
    
    def self.find_matching_section(date, sitting_type, start_column, end_column)
      if end_column
        Section.where("date = ? and sitting_type = ? and start_column <= ? and end_column >= ?", date, sitting_type, start_column, end_column).order("start_column DESC").limit(1).first
      else
        sections = Section.where("date = ? and sitting_type = ? and start_column <= ? and end_column >= ?", date, sitting_type, start_column, start_column)
        if sections.count > 1 and sections.first.section_type =~ /Group/
          sections[1]
        else
          sections[0]
        end
      end
    end
    
    def self.sitting_type_from_db_sitting_type(db_sitting_type)
      case db_sitting_type
      when /WrittenAnswersSitting/
        "Written Answers"
      when /WestminsterHallSitting/
        "Westminster Hall"
      when /WrittenStatementsSitting/
        "Written Statements"
      when /GrandCommitteeReportSitting/
        "Grand Committee report"
      when /LordsReport/
        "Lords reports"
      when /HouseOf(.*)Sitting/
        "#{$1} sitting"
      end
    end
    
    def self.find_house(text)
      if match = REFERENCE_PATTERN.match(text)
        house_id = match[1]
        house_id = house_id.upcase if house_id
        if house_id == 'C'
          return "Commons"
        elsif house_id == 'L'
          return "Lords"
        end
      end
      nil
    end
    
    def self.find_date(text)
      if (match = DATE_PATTERN.match(text))
        month = match[2].capitalize
        month_index = if month == 'Sept'
          9
        elsif MONTHS.index(month)
          MONTHS.index(month) + 1
        elsif SHORT_MONTHS.index(month)
          SHORT_MONTHS.index(month) + 1
        end
        
        begin
          Date.new(match[match.size - 1].to_i, month_index, match[1].to_i)
        rescue
          nil
        end
      else
        nil
      end
    end
end
