# stuffing the old subclasses class method inelegantly back into ActiveRecord
# but purely for the sake of running acts_as_solr
class ActiveRecord::Base
  def self.subclasses
    self.descendants
  end
end