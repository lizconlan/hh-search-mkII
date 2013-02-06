# copied from: https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/present_on_date/lib/present_on_date.rb

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
      include PresentOnDate::InstanceMethods
      extend PresentOnDate::SingletonMethods
    end
  end

  module InstanceMethods

    def present_on_date_title
      if present_on_date_options[:title]
        present_on_date_find present_on_date_options[:title]
      elsif respond_to? :name
        name
      elsif respond_to? :title
        title
      else
        self.class.name.tableize.singularize.gsub('_',' ') + ' ' + id.to_s
      end
    end

    def present_on_date_find reference, date=nil
      calls = reference.split('.')
      result = self
      calls.each do |call|
        if date
          result = result.send(call.to_sym, date)
        else
          result = result.send(call.to_sym)
        end
      end
      result
    end

    def present_on_date_url_helper_method
      if present_on_date_options[:url_helper_method]
        present_on_date_options[:url_helper_method].to_sym
      else
        (self.class.name.tableize.singularize+'_path').to_sym
      end
    end

    def present_on_date_url_parameter
      if present_on_date_options[:url_parameter]
        calls = present_on_date_options[:url_parameter].split('.')
        result = self
        calls.each do |call|
          result = result.send(call.to_sym)
        end
        result
      else
        self
      end
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

    def counts_in_interval start_date, end_date
      dates = present_dates_in_interval(start_date, end_date)
      dates.inject({}) do |counts, d|
        counts[d] = 0 unless counts.has_key?(d)
        counts[d] = counts[d] + 1
        counts
      end
    end
    
    def present_on_date? date
      exists = false
      present_on_date_fields.each do |date_field|
        if exists?(date_field => date)
          exists = true
          break
        end
      end
      exists
    end
    
    def find_all_present_in_interval start_date, end_date 
      found = []
      present_on_date_fields.each do |date_field|
        date_condition = ["#{date_field} >= ? and #{date_field} <= ?", start_date, end_date]
        found = found + send("find", :all, :conditions => date_condition, :order => "#{date_field} asc")
      end
      found
    end

    def find_all_present_on_date date
      found = []
      if present_on_date? date
        present_on_date_fields.each do |date_field|
          found = found + send("find_all_by_#{date_field}".to_sym, date)
        end
      end
      found
    end

    def find_all_present_on_date_grouped date
      found = find_all_present_on_date date

      if(present_on_date_options[:group_by] or present_on_date_options[:group_by_with_date])
        group_by = present_on_date_options[:group_by]
        group_by = present_on_date_options[:group_by_with_date] unless group_by
        on_date = present_on_date_options[:group_by_with_date] ? date : nil
        
        found = found.group_by { |x| x.present_on_date_find(group_by, on_date) }

        if present_on_date_options[:sort_by]
          found.keys.each { |group| sort_it(found[group]) }
        end
        found
      else
        {''=> sort_it(found)}
      end
    end
    
    def sort_it list
      field = present_on_date_options[:sort_by]
      if field
        list.sort! { |a,b| a.present_on_date_find(field) <=> b.present_on_date_find(field) }
      else
        list
      end
    end
  end
end