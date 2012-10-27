class Person < ActiveRecord::Base
  has_many :commons_memberships
  has_many :lords_memberships
  
  def name
    if / of$/.match(honorific)
      part_list = [honorific, lastname]
    else
      part_list = [honorific, firstname, lastname]
    end
    part_list.join(' ').strip
  end
end