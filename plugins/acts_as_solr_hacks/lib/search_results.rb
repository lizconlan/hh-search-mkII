module ActsAsSolr #:nodoc:

  class SearchResults
    
    # Returns the highlighted fields which one has asked for..
    def highlights
      @solr_data[:highlights]
    end
  
  end
  
end