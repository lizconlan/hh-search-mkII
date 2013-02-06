# encoding: utf-8

# based loosely on an extract from: https://github.com/millbanksystems/hansard/blob/master/app/models/person.rb

class Person < ActiveRecord::Base
  
  def self.find_partial_matches(partial, limit=5)
    return [] if partial.strip.blank?
    
    conditions = ""
    lastname = ""
    firstname = ""
    results = do_partial_search(partial, limit)
    
    secondary_limit = limit - results.size
    
    namelist = partial.split(/-| /)
    while secondary_limit > 0
      if namelist.size > 3 and lastname.split(/-| /).size != 3 and lastname.split(/-| /).size !=2
        chars = partial.scan(/-| /)
        lastname = "#{namelist[-3]}#{chars[-2]}#{namelist[-2]}#{chars.last}#{namelist.last}"
        id_list = results.map{ |x| x.id }.join(",")
        conditions = " AND ID not in (#{id_list})" unless id_list.empty?
        results += do_partial_search(lastname, secondary_limit, conditions)
      elsif namelist.size > 2 and lastname.split(/-| /).size != 2
        chars = partial.scan(/-| /)
        lastname = "#{namelist[-2]}#{chars.last}#{namelist.last}"
        id_list = results.map{ |x| x.id }.join(",")
        conditions = " AND ID not in (#{id_list})" unless id_list.empty?
        results += do_partial_search(lastname, secondary_limit, conditions)
      elsif namelist.size > 1 and firstname.blank?
        firstname = namelist.first
        lastname = namelist.last
        id_list = results.map{ |x| x.id }.join(",")
        conditions = " AND ID not in (#{id_list})" unless id_list.empty?
        results += do_partial_search_against_full_name_and_last_name(lastname, firstname, secondary_limit, conditions)
      else
        lastname = namelist.last
        id_list = results.map{ |x| x.id }.join(",")
        conditions = " AND ID not in (#{id_list})" unless id_list.empty?
        results += do_partial_search(lastname, secondary_limit, conditions)
        break
      end
    end
    
    results
  end
  
  private
    def self.do_partial_search(lastname, limit, exclusions="")
      find_options = { :conditions => [ "LOWER(lastname) LIKE ?", '%' + lastname.strip.downcase + '%' ],
                       :order => "lastname ASC, name ASC" }
      unless exclusions.blank?
        find_options[:conditions][0] += exclusions
      end
      
      find_options[:limit] = limit if limit
      find(:all, find_options)
    end
    
    def self.do_partial_search_against_full_name_and_last_name(lastname, firstname, limit, exclusions="")
      find_options = { :conditions => [ "LOWER(lastname) LIKE ? AND LOWER(full_name) LIKE ?", '%' + lastname.strip.downcase + '%', '%' + firstname.strip.downcase + ' %' ],
                       :order => "lastname ASC, name ASC" }
      unless exclusions.blank?
        find_options[:conditions][0] += exclusions
      end
      
      find_options[:limit] = limit if limit
      find(:all, find_options)
      
    end
end