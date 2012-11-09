require 'date'

class Timeline
  attr_reader :title, :prev_link, :prev_text, :next_link, :next_text, :blocks, :block_captions ,:header_text, :header_link, :min_date, :max_date, :resolution
  
  def initialize(items, options={})
    validate_args(items)
    @blocks = []
    @block_captions = []
    @min_date = "1803-01-01"
    @max_date = "2005-12-12"
    @options = options
    
    items = items.sort_by{ |_, count| count }.reverse
    @divider = items.first[1] / 40.0
    @items = items.sort_by{ |date, _| Date.parse(date) }
    
    if options[:resolution] and expected_resolutions.include?(options[:resolution])
      @resolution = options[:resolution]
    else
      @resolution = determine_resolution()
    end
    
    create_timeline()
  end
  
  def self.number_to_ordinal(num)
    num = num.to_i
    if (10...20)===num
      "#{num}th"
    else
      ordinal = %w{ th st nd rd th th th th th th }
      "#{num}#{ordinal[num.modulo(10)]}"
    end
  end
  
  def expected_resolutions
    ["month", "year", "decade", "century"]
  end
  
  private
    def validate_args(items)
      raise ArgumentError.new('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]') unless items.is_a?(Array)
      items.each do |item|
        raise ArgumentError.new('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]') unless item.is_a?(Array)
        raise ArgumentError.new('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]') unless item.length == 2
        begin
          test = Date.parse(item[0])
        rescue
          raise ArgumentError.new('first part of nested array must be a date string - e.g. [["1806-12-24", 16], ["1908-10-04", 2]]')
        end
        raise ArgumentError.new('second part of nested array must be an integer - e.g. [["1806-12-24", 16], ["1908-10-04", 2]]') unless item[1].is_a?(Integer)
      end
    end
    
    def create_timeline
      data = @items.reverse
      vars = {}
      
      case @resolution
      when "month"
        vars[:year], vars[:month] = @options[:month].split("-")
        vars[:year] = vars[:year].to_i
        vars[:month] = vars[:month].to_i
        vars[:month_name] = Date::MONTHNAMES[vars[:month]][0..2]
        set_chart_labels(vars)
        start = 1
        stop = ((Date.parse("#{vars[:year]}-#{vars[:month]}-01") >> 1) - 1).day
        create_blocks(start, stop, data, vars)
      when "year"
        @title = vars[:year] = @options[:year]
        vars[:year] = vars[:year].to_i
        set_chart_labels(vars)
        start = 1
        stop = 12
        create_blocks(start, stop, data, vars)
      when "decade"
        @title = vars[:decade] = @options[:decade]
        vars[:decade] = vars[:decade].gsub("s", "").to_i
        vars[:century] = @options[:decade][0..1].to_i + 1
        set_chart_labels(vars)
        start = vars[:decade]
        stop = vars[:decade]+9
        create_blocks(start, stop, data, vars)
      when "century"
        vars[:century] = @options[:century].gsub("C", "").to_i
        set_chart_labels(vars)
        start = 0
        stop = 9
        create_blocks(start, stop, data, vars)
      end
    end
    
    def set_chart_labels(vars)
      min_year = Date.parse(@min_date).year
      max_year = Date.parse(@max_date).year
      case @resolution
      when "month"
        @title = "#{vars[:month_name]} #{vars[:year]}"
        @header_text = vars[:year]
        @header_link = {"year" => vars[:year]}
        last_month = vars[:month] > 1 ? vars[:month] - 1 : 12
        @prev_text = Date::MONTHNAMES[last_month][0..2]
        last_year = last_month < 12 ? vars[:year] : vars[:year]-1
        @prev_link = {"month" => "#{last_year}-#{last_month}"} unless last_year < min_year
        next_month = vars[:month] < 12 ? vars[:month] + 1 : 1
        @next_text = Date::MONTHNAMES[next_month][0..2]
        next_year = next_month > 1 ? vars[:year] : vars[:year]+1
        @next_link = {"month" => "#{next_year}-#{next_month}"} unless next_year > max_year
      when "year"
        @header_text = "#{vars[:year].to_s[0..2]}0s"
        @header_link = {"decade" => "#{vars[:year].to_s[0..2]}0s"}
        @prev_text = (vars[:year]-1).to_s
        @prev_link = {"year" => "#{vars[:year]-1}"} unless vars[:year]-1 < min_year
        @next_text = (vars[:year]+1).to_s
        @next_link = {"year" => "#{vars[:year]+1}"} unless vars[:year]+1 > max_year
      when "decade"
        @header_text = "#{self.class.number_to_ordinal(vars[:century])} century"
        @header_link = {"century" => "C#{vars[:century]}"}
        @prev_text = ("#{vars[:decade] - 10}s")
        @prev_link = {"decade" => "#{vars[:decade]-10}s"} unless vars[:decade]-10 < min_year
        @next_text = ("#{vars[:decade] + 10}s")
        @next_link = {"decade" => "#{vars[:decade]+10}s"} unless vars[:decade]+10 > max_year
      when "century"
        last_century = vars[:century] - 1
        @prev_text = "#{self.class.number_to_ordinal(last_century)} century"
        @prev_link = {"century" => "C#{last_century}"} unless (last_century-1) < min_year.to_s[0..1].to_i
        next_century = vars[:century] + 1
        @next_text = "#{self.class.number_to_ordinal(next_century)} century"
        @next_link = {"century" => "C#{next_century}"} unless (next_century-1) > max_year.to_s[0..1].to_i
        @title = "#{self.class.number_to_ordinal(vars[:century])} century"
      end
    end
    
    def set_date_part(current_date)
      case @resolution
      when "month"
        current_date.day
      when "year"
        current_date.month
      when "decade"
        current_date.year
      when "century"
        "#{current_date.year.to_s[0..2]}0".to_i
      end
    end
    
    def make_timeblock(unit, vars)
      case @resolution
      when "month"
        TimelineBlock.new({"day"=>"#{vars[:year]}-#{vars[:month]}-#{unit}"})
      when "year"
        TimelineBlock.new({"month" => "#{vars[:year]}-#{unit}"})
      when "decade"
        TimelineBlock.new({"year" => unit})
      when "century"
        TimelineBlock.new({"decade" => "#{unit}s"})
      end
    end
    
    def set_caption(unit, vars, active_link)
      case @resolution
      when "month"
        if active_link
          TimelineCaption.new(unit, {"day"=>"#{vars[:year]}-#{vars[:month]}-#{unit}"}, "on #{Date::MONTHNAMES[vars[:month]]} #{unit}, #{vars[:year]}")
        else
          TimelineCaption.new(unit)
        end
      when "year"
        if active_link
          TimelineCaption.new(Date::MONTHNAMES[unit][0..2], {"month" => "#{vars[:year]}-#{unit}"}, "in #{Date::MONTHNAMES[unit][0..2]}")
        else
          TimelineCaption.new(Date::MONTHNAMES[unit][0..2])
        end
      when "decade"
        if active_link
          TimelineCaption.new(unit, {"year" => unit}, "in #{unit}")
        else
          TimelineCaption.new(unit)
        end
      when "century"
        if active_link
          TimelineCaption.new("#{unit}s", {"decade" => "#{unit}s"}, "in the #{unit}s")
        else
          TimelineCaption.new("#{unit}s")
        end
      end
    end
    
    def create_blocks(start, stop, data, vars)
      (start..stop).to_a.each do |block_unit|
        block_unit = block_unit*10+(vars[:century]-1)*100 if @resolution == "century"
        current_date = Date.parse(data.last[0]) unless data.empty?
        date_part = set_date_part(current_date) unless data.empty?
        if !(data.empty?) and date_part == block_unit
          block = make_timeblock(block_unit, vars)
          date_part = set_date_part(current_date) unless data.empty?
          while !(data.empty?) and date_part == block_unit
            process_loop(data, block)
            unless data.empty?
              current_date = Date.parse(data.last[0])
              date_part = set_date_part(current_date)
            end
          end
          if block.bars.count > 6
            consolidate_bars(block)
          end
        else
          block = TimelineBlock.new("")
        end
        @blocks << block
        if block.bars.first and block.bars.first.height > 0
          @block_captions << set_caption(block_unit, vars, true)
        else
          @block_captions << set_caption(block_unit, vars, false)
        end
      end
    end
    
    def process_loop(data, block)
      current = data.pop
      bar = TimelineBar.new( (current[1] / @divider).round )
      block.bars << bar
    end
    
    def consolidate_bars(block)
      bar_heights = []
      tallest = 0
      tally = 0
      factor = (block.bars.count / 6.0).ceil
      block.bars.each_with_index do |bar, index|
        tally += bar.height
        if (index+1).modulo(factor) == 0
          bar_heights << tally
          tallest = tally if tally > tallest
          tally = 0
        end
      end
      bar_heights << tally
      tallest = tally if tally > tallest
      divider = tallest / 40.0
      block.bars = []
      bar_heights.each do |height|
        block.bars << TimelineBar.new( (height / divider).round )
      end
    end
    
    def determine_resolution()
      first_date = Date.parse(@items.first[0])
      last_date = Date.parse(@items.last[0])
      
      if first_date.year == last_date.year
        if first_date.month == last_date.month
          @options[:month] = "#{first_date.year}-#{first_date.month}"
          return "month"
        else
          @options[:year] = first_date.year.to_s
          return "year"
        end
      else
        if first_date.year.to_s[0..2] == last_date.year.to_s[0..2]
          @options[:decade] = "#{first_date.year.to_s[0..2]}0s"
          return "decade"
        else
          @options[:century] = "#{first_date.year.to_s[0..1].to_i+1}C"
          return "century"
        end
      end
    end
end

class TimelineBlock
  attr_accessor :link, :bars
  
  def initialize(link)
    @link = link
    @bars = []
  end
end

class TimelineBar
  attr_accessor :height
  
  def initialize(height)
    @height = height
  end
end

class TimelineCaption
  attr_accessor :link, :text, :title_text
  
  def initialize(text, link=nil, title_text=nil)
    @text = text
    @link = link if link
    @title_text = title_text if title_text
  end
end