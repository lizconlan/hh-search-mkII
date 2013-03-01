# http://localhost:8982/solr/mlt?q=id:%22MemberContribution:21345%22&rows=1&mlt.mindf=2&mlt.interestingTerms=list&mlt.match.include=false

class Solr::Request::MoreLikeThis < Solr::Request::Select

  def initialize(params)
    super('mlt')
    @params = params
  end

  def handler
    'mlt'
  end
    
  def to_hash
    hash = super
    hash[:q] = @params[:query]
    hash['mlt.fl'] = @params[:field_list].join(',') if @params[:field_list]
    hash['mlt.mindf'] = @params[:minimum_document_frequency]
    hash['mlt.mintf'] = @params[:minimum_term_frequency]
    hash['mlt.minwl'] = @params[:minimum_word_length]
    hash['mlt.maxwl'] = @params[:maximum_word_length]
    hash['mlt.maxqt'] = @params[:max_query_terms]
    hash['mlt.maxntp'] = @params[:max_tokens]
    hash['mlt.boost'] = @params[:boost]
    hash['mlt.match.include'] = @params[:include]
    hash['mlt.match.offset'] = @params[:offset]
    hash['mlt.interestingTerms'] = @params[:interesting_terms]
    return hash
  end

end