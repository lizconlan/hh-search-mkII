require 'acts_as_solr'
require_relative '../minitest_helper.rb'
require_relative '../../lib/search.rb'
require_relative '../../lib/date_parser.rb'
require_relative '../../models/person.rb'

LAST_DATE = Date.new(2005, 12, 31)
FIRST_DATE = Date.new(1803, 1, 1)

class SearchTest < MiniTest::Spec
  describe Search do
    describe "when asked to find_matches" do
      it "should invoke Person.find_partial_matches" do
        query = "foo"
        DateParser.stubs(:date_match)
        Person.expects(:find_partial_matches).with(query, 5)
        
        search = Search.new({:query => query})
      end
      
      it "should invoke DateParser.date_match" do
        query = "foo"
        DateParser.expects(:date_match).with(query)
        Person.stubs(:find_partial_matches)
        
        search = Search.new({:query => query})
      end
    end
    
    describe "when initializing the search" do
      before do
        Search.any_instance.stubs(:find_matches).returns([])
      end
      
      it "should deal with time resolution options" do
        search = Search.new({:query => "foo", :century => "C19"})
        search.resolution.must_equal(:century)
        search.start_date.must_equal(Date.parse("1800-01-01"))
        search.end_date.must_equal(Date.parse("1899-12-31"))
        search.filters.must_equal([search.start_date])
        
        search = Search.new({:query => "foo", :decade => "1980s"})
        search.resolution.must_equal(:decade)
        search.start_date.must_equal(Date.parse("1980-01-01"))
        search.end_date.must_equal(Date.parse("1989-12-31"))
        
        search = Search.new({:query => "foo", :year => "1982"})
        search.resolution.must_equal(:year)
        search.start_date.must_equal(Date.parse("1982-01-01"))
        search.end_date.must_equal(Date.parse("1982-12-31"))
        
        search = Search.new({:query => "foo", :month => "1982-01"})
        search.resolution.must_equal(:month)
        search.start_date.must_equal(Date.parse("1982-01-01"))
        search.end_date.must_equal(Date.parse("1982-01-31"))
        
        search = Search.new({:query => "foo", :day => "1982-04-12"})
        search.resolution.must_equal(:day)
        search.start_date.must_equal(Date.parse("1982-04-12"))
        search.end_date.must_equal(Date.parse("1982-04-12"))
      end
      
      it "should sanitize the query" do        
        search = Search.new({:query => '<b>foo</b>'})
        search.query.must_equal("foo")
      end
      
      it "should set sort correctly from the passed options" do
        search = Search.new({:query => "foo", :sort => 'reverse_date'})
        search.sort.must_equal('reverse_date')
        search.search_options.must_equal({:offset=>0, :limit=>10, :highlight=>{:fields=>["solr_text"], :prefix=>"<em>", :suffix=>"</em>", :require_field_match=>false, :fragsize=>200}, :facets=>{:fields=>[:person_id, :date, :sitting_type], :zeros=>false}, :order=>"date desc"})
        
        search = Search.new({:query => "foo", :sort => 'date'})
        search.sort.must_equal('date')
        search.search_options.must_equal({:offset=>0, :limit=>10, :highlight=>{:fields=>["solr_text"], :prefix=>"<em>", :suffix=>"</em>", :require_field_match=>false, :fragsize=>200}, :facets=>{:fields=>[:person_id, :date, :sitting_type], :zeros=>false}, :order=>"date asc"})
      end
      
      it "should not break sort_options when given an invalid sort option" do
        search = Search.new({:query => "foo", :sort => 'squirrel!'})
        search.sort.must_equal('squirrel!')
        search.search_options.must_equal({:offset=>0, :limit=>10, :highlight=>{:fields=>["solr_text"], :prefix=>"<em>", :suffix=>"</em>", :require_field_match=>false, :fragsize=>200}, :facets=>{:fields=>[:person_id, :date, :sitting_type], :zeros=>false}})
      end
      
      it "should set page and offset correctly from the passed options" do
        search = Search.new({:query => "foo", :page => 42})
        search.page.must_equal(42)
        search.offset.must_equal(410)
        search.first_result.must_equal(411)
        search.search_options.must_equal({:offset=>410, :limit=>10, :highlight=>{:fields=>["solr_text"], :prefix=>"<em>", :suffix=>"</em>", :require_field_match=>false, :fragsize=>200}, :facets=>{:fields=>[:person_id, :date, :sitting_type], :zeros=>false}})
        
        search = Search.new({:query => "foo"})
        search.page.must_equal(1)
        search.offset.must_equal(0)
      end
      
      it "should set num_per_page correctly from the passed options" do
        search = Search.new({:query => "foo", :num_per_page => 5})
        search.num_per_page.must_equal(5)
        
        search = Search.new({:query => "foo"})
        search.num_per_page.must_equal(10)
      end
      
      it "should set speakers_to_display correctly from the passed options" do
        search = Search.new({:query => "foo", :speakers_to_display => 10})
        search.speakers_to_display.must_equal(10)
        
        search = Search.new({:query => "foo"})
        search.speakers_to_display.must_equal(5)
      end
      
      it "should set sitting_type correctly from the passed options" do
        search = Search.new({:query => "foo", :type => "Written Answers"})
        search.sitting_type.must_equal("Written Answers")
        search.filters.must_equal(["Written Answers"])
      end
      
      describe "when passed options that include a speaker" do      
        it "should invoke Person.find_by_slug" do
          query = "foo"
          mock_result = Person.new
          Person.expects(:find_by_slug).with("mr-jim-hacker")

          search = Search.new({:query => query, :speaker => 'mr-jim-hacker'})
        end

        it "should set the speaker related properties" do
          query = "foo"
          mock_result = Person.new
          Person.stubs(:find_by_slug).returns(mock_result)

          search = Search.new({:query => query, :speaker => 'mr-jim-hacker'})
          search.speaker.must_equal(mock_result)
          search.filters.must_equal([mock_result])
        end
      end
      
      it "should set display_all_speakers correctly from the passed options" do
        search = Search.new({:query => "foo", :all_speaker_filters => true})
        search.display_all_speakers.must_equal(true)
      end
    end

    describe "when creating the search string" do
      before do
        Search.any_instance.stubs(:find_matches).returns([])
        @query = "test string"
      end
      
      it "should set the solr_text to the value of the query" do
        search = Search.new({:query => @query})
        
        search.search_string.must_equal("solr_text:#{@query}")
      end
      
      it "should set person_id when there is a matching speaker" do
        person = Person.new()
        person.id = 42
        Person.expects(:find_by_slug).returns(person)
        search = Search.new({:query => @query, :speaker => 'mr-jim-hacker'})
        
        search.search_string.must_equal("solr_text:#{@query} AND person_id:\"42\"")
      end
      
      it "should set the sitting_type" do
        search = Search.new({:query => @query, :type => "Lords"})
        
        search.search_string.must_equal("solr_text:#{@query} AND sitting_type:\"Lords\"")
      end
      
      it "should cope with interval queries" do
        search = Search.new({:query => @query, :decade => "1980s"})
        
        search.search_string.must_equal("solr_text:#{@query} AND date:[1980-01-01 TO 1989-12-31]")
      end
    end

    describe "when searching for stuff" do
      before do
        mock_logger = mock()
        mock_logger.stubs(:info)
        Search::RAILS_DEFAULT_LOGGER = mock_logger
        @search = Search.new({:query => "foo", :decade => "1980s", :type => "Lords", :page => 2})
        @results = ActsAsSolr::SearchResults.new(:total_pages => 2, :total => 15)
      end
      
      it "should call Contribution.find_by_solr" do
        Contribution.expects(:find_by_solr).with("solr_text:foo AND sitting_type:\"Lords\" AND date:[1980-01-01 TO 1989-12-31]", @search.search_options).returns(@results)
        @search.get_results
      end
      
      it "should return the expected attributes" do
        Contribution.stubs(:find_by_solr).with("solr_text:foo AND sitting_type:\"Lords\" AND date:[1980-01-01 TO 1989-12-31]", @search.search_options).returns(@results)
        @search.get_results
        
        @search.results.must_equal(@results.results)
        @search.results_size.must_equal(15)
        @search.last_result.must_equal(15)
        @search.last_page.must_equal(2)
        @search.any_facets?.must_equal(false)
      end
    end
  end
end