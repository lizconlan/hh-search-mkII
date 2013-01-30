# encoding: utf-8

# extracted from: https://github.com/millbanksystems/hansard/blob/master/app/models/person.rb

class Person < ActiveRecord::Base
  
  def self.find_partial_matches(partial, limit=5)
    namelist = partial.split(/-| /)
    lastname = namelist.last
    find_options = { :conditions => [ "LOWER(lastname) LIKE ?", '%' + lastname.strip.downcase + '%' ],
                     :order => "lastname ASC" }
    find_options[:limit] = limit if limit
    find(:all, find_options)
  end
end