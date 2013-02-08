# adapted from: https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/present_on_date/lib/present_on_date.rb

require File.dirname(__FILE__) + '/date_extension'

# This module is designed to be mixed in with an ActiveRecord model
module PresentOnDate

  def self.included(base) # :nodoc:
    base.extend ClassMethods  
  end

  module ClassMethods 
    
    # In the ActiveRecord model you wish to make available
    # by one or more date fields, add a call to acts_as_present_on_date
    # below the class definition.
    #
    # For example, if you want to expose :start_date and :end_date
    #
    #   acts_as_present_on_date [:start_date, :end_date]
    #
    # Other examples:
    # 
    #   acts_as_present_on_date [:start_date, :end_date],
    #       :title => 'debate_title',
    #       :url_method => 'individual_path',
    #       :url_parameter => 'individual'
    #
    #   acts_as_present_on_date :date,
    #       :title => 'individual.fullname',
    #       :url_helper_method => 'individual_path',
    #       :url_parameter => 'individual'
    #
    # This will automatically make all the methods in this module available
    # in the model.
    #
    def acts_as_present_on_date(fields, options={})
      cattr_accessor :present_on_date_fields
      cattr_accessor :present_on_date_options
      raise ':fields option must be specified' unless fields

      fields = [ fields ] unless fields.is_a?(Array)

      fields.each do |field|
        raise 'field must be a symbol: ' + field.to_s unless field.is_a?(Symbol)
      end
      options.each_value do |option|
        raise 'option value must be a string: ' + option.to_s unless option.is_a?(String)
      end
      
      self.present_on_date_fields = fields
      self.present_on_date_options = options
      extend PresentOnDate::SingletonMethods
    end
  end
  
  module SingletonMethods
    
    def present_dates_in_interval start_date, end_date
      dates = []
      present_on_date_fields.each do |date_field|
        date_condition = ["#{date_field} >= ? and #{date_field} <= ?", start_date, end_date]
        
        found_in_interval = send("find", :all,
            :select => date_field,
            :conditions => date_condition)
        
        dates += found_in_interval.collect { |m| m.send(date_field) }
      end
      dates
    end
  end
end