
require File.dirname(__FILE__) + '/acts_methods'
require File.dirname(__FILE__) + '/class_methods'
require File.dirname(__FILE__) + '/instance_methods'
require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/search_results'
require File.dirname(__FILE__) + '/solr'

module ActsAsSolr
  
  class Post    
    
    def self.execute(request)
      begin
        unless @connection
          if File.exists?(RAILS_ROOT+'/config/solr.yml')
            config = YAML::load_file(RAILS_ROOT+'/config/solr.yml')
            url = config[RAILS_ENV]['url']
            # for backwards compatibility
            url ||= "http://#{config[RAILS_ENV]['host']}:#{config[RAILS_ENV]['port']}/#{config[RAILS_ENV]['servlet_path']}"
          else
            url = 'http://localhost:8982/solr'
          end
          @connection = Solr::Connection.new(url, :timeout => 120)
        end
        return @connection.send(request)
      rescue 
        raise "Couldn't connect to the Solr server at #{url}. #{$!}"
        false
      end
    end
  end
  
end

# reopen ActiveRecord and include the acts_as_solr method
ActiveRecord::Base.extend ActsAsSolr::ActsMethods

