class Solr::Response::MoreLikeThis < Solr::Response::Ruby
  
  attr_accessor :terms
  
  def initialize(ruby_code)
    super
    @response = @data['response']
    raise "response section missing" unless @response.kind_of? Hash
    @terms = @data['interestingTerms']
  end
  
  
end