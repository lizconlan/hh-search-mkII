class Solr::Response::Standard < Solr::Response::Ruby
    
  def highlighting
    @data['highlighting']
  end

end