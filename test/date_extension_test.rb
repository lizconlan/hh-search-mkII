require 'active_record'
require 'date'
require_relative 'minitest_helper.rb'
require_relative '../lib/date_extension.rb'
require_relative '../models/contribution.rb'
require_relative '../models/section.rb'

RAILS_ROOT = File.dirname("..")

class DateExtensionTest < MiniTest::Spec
  describe Date do
    test_date = Date.parse("2012-02-16")
    
    describe "when asked for material_dates_count_upto" do
      it "should check through all the ActiveRecord models to see if they have a present_dates_in_interval method" do
        Contribution.expects(:respond_to?).with(:present_dates_in_interval)
        Person.expects(:respond_to?).with(:present_dates_in_interval)
        Section.expects(:respond_to?).with(:present_dates_in_interval)
        test_date.material_dates_count_upto(Date.parse("2012-02-17"))
      end
    end
    
    describe "when asked for the first and last of the month" do
      it "should return a 2 element array" do
        result = test_date.first_and_last_of_month()
        result.must_be_instance_of(Array)
        result.size.must_equal(2)
      end
      
      it "should return the expected first and last dates" do
        result = test_date.first_and_last_of_month()
        result.first.must_equal(Date.parse("2012-02-01"))
        result.last.must_equal(Date.parse("2012-02-29"))
      end
      
      it "should not get confused by December" do
        december = Date.parse("2012-12-04")
        result = december.first_and_last_of_month()
        result.last.must_equal(Date.parse("2012-12-31"))
      end
    end
    
    describe "when asked for the first day of the year" do
      it "should return the expected date" do
        result = test_date.first_of_year()
        result.must_equal(Date.parse("2012-01-01"))
      end
    end
    
    describe "when asked for the last day of the year" do
      it "should return the expected date" do
        result = test_date.last_of_year()
        result.must_equal(Date.parse("2012-12-31"))
      end
    end
    
    describe "when asked for the first and last days of the year" do
      it "should return an array" do
        result = test_date.first_and_last_of_year()
        result.must_be_instance_of(Array)
        result.size.must_equal(2)
      end
      
      it "should call the first_of_year and last_of_year methods" do
        test_date.expects(:first_of_year)
        test_date.expects(:last_of_year)
        test_date.first_and_last_of_year()
      end
    end
    
    describe "when asked for the first day of the decade" do
      it "should return the expected date" do
        result = test_date.first_of_decade()
        result.must_equal(Date.parse("2010-01-01"))
      end
    end
    
    describe "when asked for the last day of the decade" do
      it "should return the expected date" do
        result = test_date.last_of_decade()
        result.must_equal(Date.parse("2019-12-31"))
      end
    end
    
    describe "when asked for the first and last days of the decade" do
      it "should return an array" do
        result = test_date.first_and_last_of_decade()
        result.must_be_instance_of(Array)
        result.size.must_equal(2)
      end
      
      it "should call the first_of_decade and last_of_decade methods" do
        test_date.expects(:first_of_decade)
        test_date.expects(:last_of_decade)
        test_date.first_and_last_of_decade()
      end
    end
    
    describe "when asked for the first day of the century" do
      it "should return the expected date" do
        result = test_date.first_of_century()
        result.must_equal(Date.parse("2000-01-01"))
      end
    end
    
    describe "when asked for the last day of the century" do
      it "should return the expected date" do
        result = test_date.last_of_century()
        result.must_equal(Date.parse("2099-12-31"))
      end
    end
    
    describe "when asked for the first and last days of the century" do
      it "should return an array" do
        result = test_date.first_and_last_of_century()
        result.must_be_instance_of(Array)
        result.size.must_equal(2)
      end
      
      it "should call the first_of_century and last_of_century methods" do
        test_date.expects(:first_of_century)
        test_date.expects(:last_of_century)
        test_date.first_and_last_of_century()
      end
    end
    
    describe "when asked for interval delimiters" do
      describe "when supplied start and end dates" do
        fake_start_date = Date.parse("1980-01-01")
        fake_end_date = Date.parse("1980-12-01")
        
        it "should return the start and end dates as an array" do
          result = test_date.get_interval_delimiters(:ignore_this, {:start_date => fake_start_date, :end_date => fake_end_date})
          result.must_be_instance_of(Array)
          result.size.must_equal(2)
          result.must_equal([fake_start_date, fake_end_date])
        end
      end
      
      describe "when not given start and end dates" do
        it "should return nil when given an invalid resolution" do
          result = test_date.get_interval_delimiters(:artichoke, {})
          result.must_be_nil
        end
        
        it "should call first_and_last_of_month when asked for day" do
          test_date.expects(:first_and_last_of_month)
          test_date.get_interval_delimiters(:day, {})
        end
        
        it "should call first_and_last_of_year when asked for month" do
          test_date.expects(:first_and_last_of_year)
          test_date.get_interval_delimiters(:month, {})
        end
        
        it "should call first_and_last_of_decade when asked for year" do
          test_date.expects(:first_and_last_of_decade)
          test_date.get_interval_delimiters(:year, {})
        end
        
        it "should call first_and_last_of_century when asked for decade" do
          test_date.expects(:first_and_last_of_century)
          test_date.get_interval_delimiters(:decade, {})
        end
      end
    end
    
    describe "when asked for the string version of a decade" do
      it "should return a string in the format xxx0s" do
        test_date.decade_string.must_equal("2010s")
      end
    end
    
    describe "when asked for the string version of a century" do
      it "should return a string in the format Cxx" do
        test_date.century_string.must_equal("C21")
      end
    end
    
    describe "when asked for an ordinalized century" do
      it "should return 21st for the year 2012" do
        test_date.century_ordinal.must_equal("21st")
      end
    end
    
    describe "when asked for decade" do
      it "should return 2010 for the year 2012" do
        test_date.decade.must_equal(2010)
      end
    end
    
    describe "when calling the class method lower_resolution" do
      it "should return the next resolution up where possible" do
        Date.lower_resolution(:day).must_equal(:month)
        Date.lower_resolution(:month).must_equal(:year)
      end
      
      #not sure this behaviour's correct but
      #things have been built on top of it now, worried about "fixing"
      it "should return nil if no lower resolution is available" do
        Date.lower_resolution(:decade).must_be_nil
      end
      
      it "should return day if an invalid resolution is given" do
        Date.lower_resolution(:giraffe).must_equal(:day)
      end
    end
    
    describe "when calling the class method higher_resolution" do
      it "should return the next resolution down where possible" do
        Date.higher_resolution(:month).must_equal(:day)
        Date.higher_resolution(:year).must_equal(:month)
      end
      
      #not sure this behaviour's correct but
      #things have been built on top of it now, worried about "fixing"
      it "should return nil if no higher resolution is available" do
        Date.higher_resolution(:day).must_be_nil
      end
      
      it "should return decade if an invalid resolution is given" do
        Date.higher_resolution(:giraffe).must_equal(:decade)
      end
    end
    
    describe "when calling the class method year_from_century_string" do
      it "should return a numeric year for a given century string" do
        Date.year_from_century_string("C21").must_equal(2000)
      end
    end
    
    describe "when calling the class method first_of_century" do
      it "should return the first day of the year of the given century" do
        Date.first_of_century(21).must_equal(Date.parse("2000-01-01"))
      end
    end
  end
end