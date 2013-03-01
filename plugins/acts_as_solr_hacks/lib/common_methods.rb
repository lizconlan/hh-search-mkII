module ActsAsSolr #:nodoc:
  
  module CommonMethods
    
    # Sends the delete command to Solr
    def solr_delete_by_query(query)
      ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => query))
    end
    
    # Send a spellcheck request to Solr
    def solr_spellcheck(params)
      ActsAsSolr::Post.execute(Solr::Request::Spellcheck.new(params))
    end
    
    def solr_more_like_this(params)
      ActsAsSolr::Post.execute(Solr::Request::MoreLikeThis.new(params))
    end
    
  end
end