require 'date'
require_relative '../minitest_helper.rb'
require_relative '../../lib/date_parser.rb'
require_relative '../../models/contribution.rb'

class DateParserTest < MiniTest::Spec
  describe DateParser do
    describe "when asked for date_in_future?" do
      today = Date.today
      tomorrow = today + 1
      yesterday = today - 1
      
      it "should return nil if given the current date" do        
        DateParser.date_in_future?({:year=>today.year, :month=>"#{Date::MONTHNAMES[today.month].downcase[0..2]}", :day=>today.day, :resolution=>:day}).must_be_nil
      end
      
      it "should return nil if the date is in the past" do
        DateParser.date_in_future?({:year=>yesterday.year, :month=>"#{Date::MONTHNAMES[yesterday.month].downcase[0..2]}", :day=>yesterday.day, :resolution=>:day}).must_be_nil
      end
      
      it "should return true if the date is tomorrow" do
        DateParser.date_in_future?({:year=>tomorrow.year, :month=>"#{Date::MONTHNAMES[tomorrow.month].downcase[0..2]}", :day=>tomorrow.day, :resolution=>:day}).must_equal(true)
      end
    end
    
    describe "when asked for date_match" do
      it "should return nil if not given a valid query" do
        DateParser.date_match("squirrel").must_be_nil
        
      end
      
      it "should return nil if not given a valid date" do
        DateParser.date_match("feb 31 1892").must_be_nil
      end
      
      it "should return nil if the date is in the future" do
        DateParser.date_match("feb 4 2144").must_be_nil
      end
      
      it "should return nil if the date is not found among the Contributions" do
        Contribution.expects(:find_by_date).returns(nil)
        DateParser.date_match("february 1892").must_be_nil
      end
      
      it "should return a Hash with the year, month and resolution if given a valid month and year with matching Contributions" do
        Contribution.expects(:find_by_date).returns(mock())
        DateParser.date_match("february 1892").must_equal({:year=>1892, :month=>"feb", :resolution=>:month})
      end
      
      it "should return a Hash with the year and resolution if given a valid year with matching Contributions" do
        Contribution.expects(:find_by_date).returns(mock())
        DateParser.date_match("1892").must_equal({:year=>1892, :resolution=>:year})
      end
      
      it "should return true if given a valid date with matching Contributions" do
        Contribution.expects(:find_by_date).returns(mock())
        DateParser.date_match("4 february 1892").must_equal({:year=>1892, :month=>"feb", :day=>4, :resolution=>:day})
      end
    end
    
    describe "when asked for parse_complete_date" do
      it "should return nil if not given a valid date" do
        DateParser.parse_complete_date("invalid string").must_be_nil
      end
      
      it "should return a Hash of year, month, day an resolution if given a valid date" do
        DateParser.parse_complete_date("23 february 1685").must_equal({:year=>1685, :month=>"feb", :day=>23, :resolution=>:day})
        DateParser.parse_complete_date("23 February 1685").must_equal({:year=>1685, :month=>"feb", :day=>23, :resolution=>:day})
      end
    end
    
    describe "when asked for date_from_params" do
      it "should return the date as a Date object" do
        DateParser.date_from_params({:year=>1892, :month=>"feb", :day=>4, :resolution=>:day}).must_equal(Date.parse("1892-02-04"))
      end
    end
    
    describe "when asked for parse_month_and_year" do
      it "should return nil if given an string in the wrong format" do
        DateParser.parse_month_and_year("not helping").must_be_nil
      end
      
      it "should return nil if given a string containing a date with a year considered out of scope" do
        DateParser.parse_month_and_year("september 1442").must_be_nil
        DateParser.parse_month_and_year("september 2283").must_be_nil
      end
      
      it "should return a Hash of year, month shortname and resolution if given a valid string" do
        DateParser.parse_month_and_year("september 1892").must_equal(:year => 1892, :month => "sep", :resolution => :month)
        DateParser.parse_month_and_year("nov 1923").must_equal(:year => 1923, :month => "nov", :resolution => :month)
      end
    end
    
    describe "when asked for parse_year" do
      it "should return nil if not given a valid year" do
        DateParser.parse_year("notyear").must_be_nil
        DateParser.parse_year("1784").must_be_nil
        DateParser.parse_year("2184").must_be_nil
      end
      
      it "should return a Hash of year and resolution if given a valid year" do
        DateParser.parse_year("1892").must_equal({:year => 1892, :resolution => :year})
        DateParser.parse_year("1982").must_equal({:year => 1982, :resolution => :year})
        DateParser.parse_year("2002").must_equal({:year => 2002, :resolution => :year})
      end
    end
  end
end