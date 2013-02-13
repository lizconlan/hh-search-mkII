require 'haml'
require_relative '../minitest_helper.rb'
require_relative '../../lib/search'

LAST_DATE = Date.new(2005, 12, 31)
FIRST_DATE = Date.new(1803, 1, 1)

class PaginationTest < MiniTest::Spec
  describe "PaginationHAML" do
    before do
      haml_template = File.read(File.join(File.dirname(__FILE__) + "/../../views/", '_pagination.haml'))
      @engine = Haml::Engine.new(haml_template)
      Search.any_instance.stubs(:find_matches).returns([])
      @search = Search.new({:query => "test"})
      @page = Object.new()
      @page.stubs(:querystring_builder).returns("http://test")
    end
    
    describe "in general" do
      before do
        @search.stubs(:last_page).returns(2)
      end
      
      it "should not have a link for previous when drawing the first page" do
        @search.stubs(:page).returns(1)
        
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/<span class='disabled prev_page'>/)
      end
      
      it "should have a link for previous when not drawing the first page" do
        @search.stubs(:page).returns(2)
        
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/<span class='prev_page'>/)
      end
      
      it "should not have a link for the next page when drawing the last page" do
        @search.stubs(:page).returns(2)
        
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/<span class='disabled next_page'>/)
      end
      
      it "should have a link for next when not drawing the last page" do
        @search.stubs(:page).returns(1)
        
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/<span class='next_page'>/)
      end
    end

    describe "when on the first of many pages of results" do
      before do
        @search.stubs(:page).returns(1)
      end
      
      it "should draw navigation for pages 1 & 2 when there are 2 pages" do
        @search.stubs(:last_page).returns(2)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1, 2 & 3 when there are 3 pages" do
        @search.stubs(:last_page).returns(3)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<a href='http:\/\/test'>3<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1-6 when there are 6 pages" do
        @search.stubs(:last_page).returns(6)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<a href='http:\/\/test'>3<\/a>\n<a href='http:\/\/test'>4<\/a>\n<a href='http:\/\/test'>5<\/a>\n<a href='http:\/\/test'>6<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1-11 when there are 11 pages" do
        @search.stubs(:last_page).returns(11)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<a href='http:\/\/test'>3<\/a>\n<a href='http:\/\/test'>4<\/a>\n<a href='http:\/\/test'>5<\/a>\n<a href='http:\/\/test'>6<\/a>\n<a href='http:\/\/test'>7<\/a>\n<a href='http:\/\/test'>8<\/a>\n<a href='http:\/\/test'>9<\/a>\n<a href='http:\/\/test'>10<\/a>\n<a href='http:\/\/test'>11<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1-9 then 11 & 12 if there are 12 pages" do
        @search.stubs(:last_page).returns(12)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<a href='http:\/\/test'>3<\/a>\n<a href='http:\/\/test'>4<\/a>\n<a href='http:\/\/test'>5<\/a>\n<a href='http:\/\/test'>6<\/a>\n<a href='http:\/\/test'>7<\/a>\n<a href='http:\/\/test'>8<\/a>\n<a href='http:\/\/test'>9<\/a>\n...\n<a href='http:\/\/test'>11<\/a>\n<a href='http:\/\/test'>12<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1-9 then 20 & 21 if there are 21 pages" do
        @search.stubs(:last_page).returns(21)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<span class='current'>1<\/span>\n<a href='http:\/\/test'>2<\/a>\n<a href='http:\/\/test'>3<\/a>\n<a href='http:\/\/test'>4<\/a>\n<a href='http:\/\/test'>5<\/a>\n<a href='http:\/\/test'>6<\/a>\n<a href='http:\/\/test'>7<\/a>\n<a href='http:\/\/test'>8<\/a>\n<a href='http:\/\/test'>9<\/a>\n...\n<a href='http:\/\/test'>20<\/a>\n<a href='http:\/\/test'>21<\/a>\n<span class='next_page'>/)
      end
    end
    
    describe "when in the middle of many pages of results" do
      before do
        @search.stubs(:last_page).returns(30)
      end
      
      it "should draw navigation for pages 1 & 2 then 14-22 then 29 & 30 for page 18 of 30" do
        @search.stubs(:page).returns(18)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<a href='http:\/\/test'>1<\/a>\n<a href='http:\/\/test'>2<\/a>\n...\n<a href='http:\/\/test'>14<\/a>\n<a href='http:\/\/test'>15<\/a>\n<a href='http:\/\/test'>16<\/a>\n<a href='http:\/\/test'>17<\/a>\n<span class='current'>18<\/span>\n<a href='http:\/\/test'>19<\/a>\n<a href='http:\/\/test'>20<\/a>\n<a href='http:\/\/test'>21<\/a>\n<a href='http:\/\/test'>22<\/a>\n...\n<a href='http:\/\/test'>29<\/a>\n<a href='http:\/\/test'>30<\/a>\n<span class='next_page'>/)
      end
      
      it "should draw navigation for pages 1 & 2 then 22-30 for page 23 of 30" do
        @search.stubs(:page).returns(23)
        rendered = @engine.render(@page, {:@search => @search})
        rendered.must_match(/Previous<\/a>\n<\/span>\n<a href='http:\/\/test'>1<\/a>\n<a href='http:\/\/test'>2<\/a>\n...\n<a href='http:\/\/test'>22<\/a>\n<span class='current'>23<\/span>\n<a href='http:\/\/test'>24<\/a>\n<a href='http:\/\/test'>25<\/a>\n<a href='http:\/\/test'>26<\/a>\n<a href='http:\/\/test'>27<\/a>\n<a href='http:\/\/test'>28<\/a>\n<a href='http:\/\/test'>29<\/a>\n<a href='http:\/\/test'>30<\/a>\n<span class='next_page'>/)
      end
    end
  end
end