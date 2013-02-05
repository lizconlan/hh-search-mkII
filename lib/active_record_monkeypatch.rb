class ActiveRecord::Base
  def self.subclasses
    self.descendants
  end
end