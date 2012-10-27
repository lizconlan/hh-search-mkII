# encoding: utf-8

class HansardReference

  attr_reader :house, :date, :volume, :column, :end_column, :series

  MONTHS = Date::MONTHNAMES[1..12]
  SHORT_MONTHS = Date::ABBR_MONTHNAMES[1..12]

  REFERENCE_PATTERN = /H(C|L) Deb\s+.+$/i

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

  def self.create_from text
    attributes = {}
    text = text.tr('.,','')
    if (match = COLUMN_NUMBER_PATTERN.match text)
      text.sub!(match[0], ' '+match[1]+match[2])
    end

    self.populate_house attributes, text
    self.populate_date attributes, text
    if attributes.has_key?(:house) || attributes.has_key?(:date)
      if match = VOLUME_PATTERN.match(text)
        attributes[:volume] = match[1].to_i
      elsif match = ALT_VOLUME_PATTERN.match(text)
        attributes[:volume] = match[1].to_i
      end

      attributes[:column], attributes[:end_column] = self.find_columns text

      if match = SERIES_PATTERN.match(text)
        attributes[:series] = match[1]
      end

      if WRITTEN_STATEMENT_PATTERN.match(text)
        attributes[:written_statement] = true
      elsif WESTMINSTER_HALL_PATTERN.match(text)
        attributes[:westminster_hall] = true
      elsif WRITTEN_ANSWER_PATTERN.match(text)
        attributes[:written_answer] = true
      elsif GRAND_COMMITTEE_PATTERN.match(text)
        attributes[:grand_committee] = true
      end
    end

    reference = HansardReference.new(attributes)
    if reference.is_reference?
      reference
    else
      nil
    end
  end

  def initialize attributes
    @house  = attributes[:house]
    @date   = attributes[:date]
    @column = attributes[:column]
    @end_column = attributes[:end_column]
    @volume = attributes[:volume] if attributes[:volume]
    @series = attributes[:series] if attributes[:series]
    @written_statement = attributes[:written_statement] if attributes[:written_statement]
    @written_answer = attributes[:written_answer] if attributes[:written_answer]
    @westminster_hall = attributes[:westminster_hall] if attributes[:westminster_hall]
    @grand_committee = attributes[:grand_committee] if attributes[:grand_committee]
  end

  def is_reference?
    (@date and @column) ? true : false
  end

  def is_written_statement?
    @written_statement ? true : false
  end

  def is_written_answer?
    @written_answer ? true : false
  end

  def is_westminster_hall?
    @westminster_hall ? true : false
  end

  def is_grand_committee?
    @grand_committee ? true : false
  end

  def year
    @date.year
  end

  def date_to_s
    @date.day.to_s + ' ' + MONTHS[@date.month - 1] + ' ' + @date.year.to_s
  end

  def find_sections
    @sections ||= search_sections
  end

  def search_sections
    sections = []
    if house == :commons
      sections << find_commons_section
    elsif house == :lords
      sections << find_lords_section
    else
      sections = find_section_without_house
    end
    sections.compact
  end
  
  def column_suffix
    find_sections.first.sitting.class.hansard_reference_suffix if !find_sections.empty?
  end
  
  private
  
    def find_in_sitting_type(sitting_type)
      sitting_type.find_section_by_column_and_date(column, date, end_column)
    end
    
    def find_commons_section
      sitting_type = nil
      if is_written_statement?
        sitting_type = CommonsWrittenStatementsSitting
      elsif is_written_answer?
        sitting_type = CommonsWrittenAnswersSitting
      elsif is_westminster_hall?
        sitting_type = WestminsterHallSitting
      else
        sitting_type = HouseOfCommonsSitting
      end
      find_in_sitting_type(sitting_type)
    end
  
    def find_lords_section
      sitting_type = nil
      if is_written_statement?
        sitting_type = LordsWrittenStatementsSitting
      elsif is_written_answer?
        sitting_type = LordsWrittenAnswersSitting
      elsif is_grand_committee?
        sitting_type = GrandCommitteeReportSitting
      else
        sitting_type = HouseOfLordsSitting
      end
      find_in_sitting_type(sitting_type)
    end
    
    def find_section_without_house
      sections = []
      if is_written_answer?
        sections << find_in_sitting_type(CommonsWrittenAnswersSitting)
        sections << find_in_sitting_type(LordsWrittenAnswersSitting)
        if sections.compact.empty?
          sections << find_in_sitting_type(WrittenAnswersSitting)
        end
      elsif is_westminster_hall?
        sections << find_in_sitting_type(WestminsterHallSitting)
      else
        sections << find_in_sitting_type(HouseOfCommonsSitting)
        sections << find_in_sitting_type(HouseOfLordsSitting)
      end
      sections
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
    
    def self.populate_house attributes, text
      if match = REFERENCE_PATTERN.match(text)
        house_id = match[1].upcase
        if house_id == 'C'
          attributes[:house] = :commons
        elsif house_id == 'L'
          attributes[:house] = :lords
        end
      end
    end

    def self.populate_date attributes, text
      if match = DATE_PATTERN.match(text)
        month = match[2].capitalize
        month_index = if month == 'Sept'
          9
        elsif MONTHS.index(month)
          MONTHS.index(month) + 1
        elsif SHORT_MONTHS.index(month)
          SHORT_MONTHS.index(month) + 1
        end

        attributes[:date] = Date.new(match[match.size - 1].to_i, month_index, match[1].to_i)
      end
    end
end
