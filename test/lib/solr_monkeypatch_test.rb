require_relative '../minitest_helper.rb'
require 'acts_as_solr'
# require_relative '../../models/contribution'
require_relative '../../lib/search_results'

class SolrMonkeypatchTest < MiniTest::Spec
  describe "SolrMonkeyPatch" do
    results = ActsAsSolr::SearchResults.new()
    
    it "should allow ActsAsSolr::SearchResults objects to respond to 'highlights'" do
      results.must_respond_to(:highlights)
    end
    
    it "should return the contents of the @solr_data[:highlights] instance variable" do
      results.instance_variable_set("@solr_data", {:highlights => ["fake result"]})
      results.highlights.must_equal(["fake result"])
    end
    
    it "should return nil if the @solr_data instance variable has not been set" do
      results.highlights.must_be_nil
    end
  end
end