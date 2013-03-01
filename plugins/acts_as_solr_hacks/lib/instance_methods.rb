module ActsAsSolr #:nodoc:
  
  module InstanceMethods

    # convert instance to Solr document
    def to_solr_doc
      # logger.debug "to_solr_doc: creating doc for class: #{self.class.name}, id: #{record_id(self)}"
      doc = Solr::Document.new
      doc.boost = validate_boost(configuration[:boost]) if configuration[:boost]
      
      doc << {:id => solr_id,
              solr_configuration[:type_field] => self.class.name,
              solr_configuration[:primary_key_field] => record_id(self).to_s}

      # iterate through the fields and add them to the document,
      configuration[:solr_fields].each do |field|
        field_name = field
        field_type = configuration[:facets] && configuration[:facets].include?(field) ? :facet : :text
        field_boost= solr_configuration[:default_boost]

        if field.is_a?(Hash)
          field_name = field.keys.pop
          if field.values.pop.respond_to?(:each_pair)
            attributes = field.values.pop
            field_type = get_solr_field_type(attributes[:type]) if attributes[:type]
            field_boost= attributes[:boost] if attributes[:boost]
          else
            field_type = get_solr_field_type(field.values.pop)
            field_boost= field[:boost] if field[:boost]
          end
        end
        value = self.send("#{field_name}_for_solr")
        value = set_value_if_nil(field_type) if value.to_s == ""
        
        # add the field to the document, but only if it's not the id field
        # or the type field (from single table inheritance), since these
        # fields have already been added above.
        if field_name.to_s != self.class.primary_key and field_name.to_s != "type"
          suffix = get_solr_field_type(field_type)
          # This next line ensures that e.g. nil dates are excluded from the 
          # document, since they choke Solr. Also ignores e.g. empty strings, 
          # but these can't be searched for anyway: 
          # http://www.mail-archive.com/solr-dev@lucene.apache.org/msg05423.html
          next if value.nil? || value.to_s.strip.empty?
          [value].flatten.each do |v|
            v = set_value_if_nil(suffix) if value.to_s == ""
            field = Solr::Field.new("#{field_name}_#{suffix}" => v.to_s)
            field.boost = validate_boost(field_boost)
            doc << field
          end
        end
      end
      
      add_includes(doc) if configuration[:include]
      # logger.debug doc.to_xml.to_s
      return doc
    end

  end
end