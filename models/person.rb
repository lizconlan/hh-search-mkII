class Person < ActiveRecord::Base
  
  def name
    if / of$/.match(honorific)
      part_list = [honorific, lastname]
    else
      part_list = [honorific, firstname, lastname]
    end
    part_list.join(' ').strip
  end
end