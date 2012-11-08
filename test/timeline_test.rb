require_relative 'minitest_helper.rb'
require_relative '../models/timeline.rb'

class TimelineTest < MiniTest::Spec
  def setup
  end
  
  describe Timeline do
    describe "when creating a new object" do
      it "should fail if not given a parameter" do
        create_fail = lambda { Timeline.new() }
        create_fail.must_raise(ArgumentError)
        err = create_fail.call rescue $!
        err.message.must_equal("wrong number of arguments (0 for 1)")
      end
      
      it "should fail if parameter is not in the expected format" do
        not_array = lambda { Timeline.new("hello") }
        not_array.must_raise(ArgumentError)
        err = not_array.call rescue $!
        err.message.must_equal('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        not_nested_array = lambda { Timeline.new(["hello"]) }
        not_nested_array.must_raise(ArgumentError)
        err = not_nested_array.call rescue $!
        err.message.must_equal('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        inner_array_too_short = lambda { Timeline.new ([["hello"]]) }
        inner_array_too_short.must_raise(ArgumentError)
        err = inner_array_too_short.call rescue $!
        err.message.must_equal('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        inner_array_too_long = lambda { Timeline.new ([["label", 2, "extra"]]) }
        inner_array_too_long.must_raise(ArgumentError)
        err = inner_array_too_long.call rescue $!
        err.message.must_equal('expected a nested array in the following format: [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        inner_array_incorrect = lambda { Timeline.new([["hello", "hello"]]) }
        inner_array_incorrect.must_raise(ArgumentError)
        err = inner_array_incorrect.call rescue $!
        err.message.must_equal('first part of nested array must be a date string - e.g. [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        inner_array_string_error = lambda { Timeline.new([["label", 84]]) }
        inner_array_string_error.must_raise(ArgumentError)
        err = inner_array_string_error.call rescue $!
        err.message.must_equal('first part of nested array must be a date string - e.g. [["1806-12-24", 16], ["1908-10-04", 2]]')
        
        count_not_a_number = lambda { Timeline.new([["1956-05-22", 44], ["1956-05-23", "33"]]) }
        count_not_a_number.must_raise(ArgumentError)
        err = count_not_a_number.call rescue $!
        err.message.must_equal('second part of nested array must be an integer - e.g. [["1806-12-24", 16], ["1908-10-04", 2]]')
      end
      
      it "should set min_date and max_date" do
        timeline = Timeline.new([["1806-12-24", 16], ["1908-10-04", 2]])
        timeline.min_date.must_equal("1803-01-01")
        timeline.max_date.must_equal("2005-12-12")
      end
      
      it "should set an appropriate resolution if none is given" do
        timeline_month = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2]])
        timeline_month.resolution.must_equal("month")
        
        timeline_year = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2]])
        timeline_year.resolution.must_equal("year")
        
        timeline_decade = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2], ["1808-10-10", 5]])
        timeline_year.resolution.must_equal("year")
        
        timeline_century = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2], ["1818-10-10", 5]])
        timeline_century.resolution.must_equal("century")
        
        timeline_century2 = timeline_century = Timeline.new([["1706-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2], ["1818-10-10", 5]])
        timeline_century2.resolution.must_equal("century")
      end
      
      it "should allow resolution to be overridden" do
        timeline = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2]], {:resolution => "year"})
        timeline.resolution.must_equal("year")
      end
      
      it "should ignore nonsensical resolutions" do
        timeline = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2]], {:resolution => "hippo"})
        timeline.resolution.must_equal("month")
      end
    end
    
    describe "when building the timeline object" do
      before do
        @timeline_month = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2]])
        @timeline_year = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2]])
        @timeline_decade = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2], ["1808-10-10", 5]])
        @timeline_century = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2], ["1818-10-10", 5]])
      end
      
      it "should create the expected number of blocks" do
        timeline_feb = Timeline.new([["1979-02-24", 16], ["1979-02-10", 2]])
        timeline_feb.blocks.count.must_equal(28)
        
        timeline_leapyear = Timeline.new([["1980-02-24", 16], ["1980-02-10", 2]])
        timeline_leapyear.blocks.count.must_equal(29)
        
        @timeline_month.blocks.count.must_equal(31)
        @timeline_year.blocks.count.must_equal(12)
        @timeline_decade.blocks.count.must_equal(10)
        @timeline_century.blocks.count.must_equal(10)
      end
      
      it "should set the chart title properly" do
        @timeline_month.title.must_equal("Dec 1806")
        @timeline_year.title.must_equal("1806")
        @timeline_decade.title.must_equal("1800s")
        @timeline_century.title.must_equal("19th century")
      end
      
      it "should set a link to the the next resolution up as the header" do
        @timeline_month.header_text.must_equal(1806)
        @timeline_month.header_link.must_equal({"year" => 1806})
        @timeline_year.header_text.must_equal("1800s")
        @timeline_year.header_link.must_equal({"decade" => "1800s"})
        @timeline_decade.header_text.must_equal("19th century")
        @timeline_decade.header_link.must_equal("century" => "C19")
      end
      
      it "should not set header information for century" do
        @timeline_century.header_text.must_equal(nil)
        @timeline_century.header_link.must_equal(nil)
      end
      
      it "should set previous and next links" do
        @timeline_month.prev_text.must_equal("Nov")
        @timeline_month.prev_link.must_equal({"month" => "1806-11"})
        @timeline_month.next_text.must_equal("Jan")
        @timeline_month.next_link.must_equal({"month" => "1806-1"})
        
        @timeline_year.prev_text.must_equal("1805")
        @timeline_year.prev_link.must_equal({"year" => "1805"})
        @timeline_year.next_text.must_equal("1807")
        @timeline_year.next_link.must_equal({"year" => "1807"})
        
        @timeline_decade.prev_text.must_equal("1790")
        @timeline_decade.prev_link.must_equal({"decade" => "1790s"})
        @timeline_decade.next_text.must_equal("1810")
        @timeline_decade.next_link.must_equal({"decade" => "1810s"})
        
        timeline_century = Timeline.new([["1900-01-01", 15]])
        timeline_century.prev_text.must_equal("19th century")
        timeline_century.prev_link.must_equal({"century" => "C19"})
        timeline_century.next_text.must_equal("21st century")
        timeline_century.next_text.must_equal({"century" => "C21"})
      end
      
      it "should not set previous links if they fall beyond min_date" do
        timeline_month = Timeline.new([["1803-01-01", 42], ["1803-01-22", 4]])
        timeline_month.prev_text.must_equal("Dec")
        timeline_month.prev_link.must_equal(nil)
        
        timeline_year = Timeline.new([["1803-01-01", 42], ["1803-02-01", 4]])
        timeline_year.prev_text.must_equal("1802")
        timeline_year.prev_link.must_equal(nil)
        
        timeline_decade = Timeline.new([["1803-01-01", 42], ["1805-01-01", 6]])
        timeline_decade.prev_text.must_equal("1790")
        timeline_decade.prev_link.must_equal(nil)
        
        @timeline_century.prev_text.must_equal("18th century")
        @timeline_century.prev_link.must_equal(nil)
      end
      
      it "should not set next links if they fall beyond max_date" do
        timeline_month = Timeline.new([["2005-12-12", 42], ["2005-12-14", 6]])
        timeline_month.next_text.must_equal("Jan")
        timeline_month.next_link.must_equal(nil)
        
        timeline_year = Timeline.new([["2005-11-12", 42], ["2005-12-12", 15]])
        timeline_year.next_text.must_equal("2006")
        timeline_year.next_link.must_equal(nil)
        
        timeline_decade = Timeline.new([["2004-11-12", 42], ["2005-12-12", 15]])
        timeline_decade.next_text.must_equal("2010s")
        timeline_decade.next_link.must_equal(nil)
        
        timeline_century = Timeline.new([["2004-11-12", 42], ["2010-11-12", 4]])
        timeline_century.next_text.must_equal("22nd century")
        timeline_century.next_link.must_equal(nil)
      end
      
      it "should set appropriate captions and caption links" do
        @timeline_month.block_captions.map{ |x| x.text }.must_equal((1..31).to_a)
        @timeline_month.block_captions.map{ |x| x.link }.must_equal([nil, nil, nil, nil, nil, nil, nil, nil, nil, {"day" => "1806-12-10"}, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil ,nil, {"day" => "1806-12-24"}, nil, nil, nil, nil, nil, nil, nil])
        @timeline_year.block_captions.map{ |x| x.text }.must_equal(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
        @timeline_year.block_captions.map{ |x| x.link }.must_equal([nil, nil, nil, nil, nil, nil, nil, nil, nil, {"month" => "1806-10"}, nil, {"month" => "1806-12"}])
        @timeline_decade.block_captions.map{ |x| x.text }.must_equal([1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809])
        @timeline_decade.block_captions.map{ |x| x.link }.must_equal([nil, nil, nil, nil, nil, nil, {"year" => 1806}, nil, {"year" => 1808}, nil])
        @timeline_century.block_captions.map{ |x| x.text }.must_equal([1800, 1810, 1820, 1830, 1840, 1850, 1860, 1870, 1880, 1890])
        @timeline_century.block_captions.map{ |x| x.link }.must_equal([{"decade" => "1800s"}, {"decade" => "1810s"}, nil, nil, nil, nil, nil, nil, nil, nil])
      end
      
      it "should set the individual bars properly" do
        @timeline_year = Timeline.new([["1806-12-24", 16], ["1806-12-10", 2], ["1806-10-10", 2]])
        @timeline_year.blocks[11].bars.count.must_equal(2)
        @timeline_year.blocks[11].bars[0].height.must_equal(5)
        @timeline_year.blocks[11].bars[1].height.must_equal(40)
      end
    end
  end
end