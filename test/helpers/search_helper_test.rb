require_relative '../minitest_helper.rb'
require_relative '../../helpers/search_helper.rb'
require_relative '../../models/contribution.rb'
require_relative '../../models/person.rb'

LAST_DATE = Date.new(2005, 12, 31)
FIRST_DATE = Date.new(1803, 1, 1)

class SearchHelperTest < MiniTest::Spec
  include SearchHelper
  
  describe SearchHelper do
    describe "when asked for month_string" do
      it "should return the longform month name if not passed any options" do
        month_string(Date.parse("2012-02-14")).must_equal("February")
      end
      
      it "should return the shortform month name if passed :brief" do
        month_string(Date.parse("2012-02-14"), {:brief => 1}).must_equal("Feb.")
      end
    end
    
    describe "when asked for format_date" do
      it "should return a decade string when asked for a decade" do
        format_date(Date.parse("2012-02-14"), :decade).must_equal("2010s")
      end
      
      it "should return a year string when asked for a year" do
        format_date(Date.parse("2012-02-14"), :year).must_equal("2012")
      end
      
      it "should return a month-year string when asked for a month" do
        format_date(Date.parse("2012-02-14"), :month).must_equal("February 2012")
      end
      
      it "should return a day-month-year string when asked for a day" do
        format_date(Date.parse("2012-02-14"), :day).must_equal("14 February 2012")
      end
      
      it "should return a century string if not passed any other resolution" do
        format_date(Date.parse("2012-02-14"), :century).must_equal("21st century")
      end
    end
    
    describe "when asked for interval_suffix" do
      it "should pick an appropriate label depending on the resolution given" do
        interval_suffix("century", "20th century", "not used by this variation").must_equal(": 20th century")
        interval_suffix(:decade, "2010s", "not used by this variation").must_equal("in the 2010s")
        interval_suffix(:year, "2010", "not used by this variation").must_equal("in 2010")
        interval_suffix(:month, "Dec", "not used by this variation").must_equal("in Dec")
        interval_suffix(:day, "not used by this variation", Date.parse("1995-11-22")).must_equal("on November 22, 1995")
      end
    end
    
    describe "when asked for show_filter" do
      it "should date string and resolution name when the filter is a Date" do
        search = mock()
        search.stubs(:resolution).returns(:century)
        show_filter(Date.parse("1995-11-22"), search).must_equal(["20th century", "century"])
      end
      
      it "should name and 'speaker' when the filter is a Person" do
        person = Person.new({:honorific => "Mr", :name => "Jim Hacker"})
        show_filter(person, nil).must_equal(["Mr Jim Hacker", "speaker"])
      end
    end
    
    describe "when asked for querystring_builder" do
      before do
        @fake_request = mock()
        @fake_request.stubs(:path_info).returns("")
      end
      
      describe "in general" do
        let(:request) { @fake_request }
        let(:params) {{}}
        
        it "should ignore everything except the first item in the options list" do
          #no, me either (and I wrote it)
          querystring_builder(:year => "1984", :sort=> "date").must_equal("?year=1984")
        end
      end
      
      describe "when the querystring already includes a page number" do
        let(:request) { @fake_request }
        let(:params) {{:page => 4}}
        
        it "should change the page number to the one supplied" do
          querystring_builder("page" => 3).must_equal("?page=3")
        end
        
        it "should remove the page number from the querystring if passed nil or 1" do
          querystring_builder("page" => nil).must_equal("")
          querystring_builder("page" => 1).must_equal("")
        end
        
        it "should append drop the page number when adding a new attribute" do
          querystring_builder(:speaker => "mr-jim-hacker").must_equal("?speaker=mr-jim-hacker")
        end
      end
      
      describe "when the querystring already includes a speaker" do
        let(:request) { @fake_request }
        let(:params) {{:speaker => "mr-jim-hacker"}}
        
        it "should slot new attributes into the querystring" do
          querystring_builder(:century => "C20").must_equal("?century=C20&speaker=mr-jim-hacker")
          querystring_builder(:type => "Commons").must_equal("?speaker=mr-jim-hacker&type=Commons")
          querystring_builder(:sort => "date").must_equal("?sort=date&speaker=mr-jim-hacker")
        end
      end
      
      describe "when the querystring already includes a date-related attribute" do
        let(:request) { @fake_request }
        let(:params) {{:decade => "1980s"}}
        
        it "should replace one with the other" do
          querystring_builder(:century => "C20").must_equal("?century=C20")
          querystring_builder(:month => "1984-11").must_equal("?month=1984-11")
          querystring_builder(:speaker => "mr-jim-hacker").must_equal("?decade=1980s&speaker=mr-jim-hacker")
        end
      end
    end
  end
end