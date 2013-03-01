module ActsAsSolr #:nodoc:
  
  module ActsMethods
    
    def acts_as_solr(options={}, solr_options={})
      
      extend ClassMethods
      include InstanceMethods
      include CommonMethods
      include ParserMethods
      
      cattr_accessor :configuration
      cattr_accessor :solr_configuration
      
      self.configuration = { 
        :fields => nil,
        :additional_fields => nil,
        :exclude_fields => [],
        :auto_commit => true,
        :include => nil,
        :facets => nil,
        :boost => nil,
        :if => "true"
      }  
      self.solr_configuration = {
        :type_field => "type_t",
        :primary_key_field => "pk_i",
        :default_boost => 1.0
      }
      
      configuration.update(options) if options.is_a?(Hash)
      solr_configuration.update(solr_options) if solr_options.is_a?(Hash)
      Deprecation.validate_index(configuration)
      
      configuration[:solr_fields] = []
      
      after_save    :solr_save
      after_destroy :solr_destroy

      if configuration[:fields].respond_to?(:each)
        process_fields(configuration[:fields])
      else
        process_fields(self.new.attributes.keys.map { |k| k.to_sym })
        process_fields(configuration[:additional_fields])
      end

    end
    
    private
    def get_field_value(field)
      configuration[:solr_fields] << field
      type  = field.is_a?(Hash) ? field.values[0] : nil
      field = field.is_a?(Hash) ? field.keys[0] : field
      define_method("#{field}_for_solr".to_sym) do
        begin
          value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.send(field.to_sym)
          case type 
            # format dates properly; return nil for nil dates 
            when :date
              value ? value.strftime("%Y-%m-%dT%H:%M:%SZ") : nil
            else value
          end
        rescue
          value = ''
          logger.debug "There was a problem getting the value for the field '#{field}': #{$!}"
        end
      end
    end
  end
end