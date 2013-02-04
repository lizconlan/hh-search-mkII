# encoding: utf-8

# based loosely on an extract from: https://github.com/millbanksystems/hansard/blob/master/app/models/person.rb

class Person < ActiveRecord::Base
  
  def self.find_partial_matches(partial, limit=5)
    conditions = ""
    results = do_partial_search(partial, limit)
    
    secondary_limit = limit - results.size
    
    namelist = partial.split(/-| /)
    if secondary_limit <= limit and namelist.size > 1
      lastname = namelist.last
      id_list = results.map{ |x| x.id }.join(",")
      conditions = " AND ID not in (#{id_list})" unless id_list.empty?
      results += do_partial_search(lastname, secondary_limit, conditions)
    end
    
    results
  end
  
  private
    def self.do_partial_search(lastname, limit, exclusions="")
      find_options = { :conditions => [ "LOWER(lastname) LIKE ?", '%' + lastname.strip.downcase + '%' ],
                       :order => "lastname ASC" }
      unless exclusions.blank?
        find_options[:conditions][0] += exclusions
      end
      
      find_options[:limit] = limit if limit
      find(:all, find_options)
    end
end