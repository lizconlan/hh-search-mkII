# copied from: https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/acts_as_solr_hacks/lib/search_results.rb

module ActsAsSolr #:nodoc:
  
  class SearchResults
    # Returns the highlighted fields which one has asked for..
    def highlights
      @solr_data[:highlights]
    end
  end
  
end