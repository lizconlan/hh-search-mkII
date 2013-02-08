# adapted from: https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/present_on_date/lib/present_on_date.rb

require File.dirname(__FILE__) + '/date_extension'

# This module is designed to be mixed in with an ActiveRecord model
module PresentOnDate

  def self.included(base) # :nodoc:
    base.extend ClassMethods  
  end

  module ClassMethods 
    def acts_as_present_on_date(fields, options={})
      cattr_accessor :present_on_date_fields
      cattr_accessor :present_on_date_options
      raise ':fields option must be specified' unless fields

      fields = [ fields ] unless fields.is_a?(Array)

      fields.each do |field|
        raise 'field must be a symbol: ' + field.to_s unless field.is_a?(Symbol)
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
        
        dates += found_in_interval.map { |m| m.send(date_field) }
      end
      dates
    end
  end
end