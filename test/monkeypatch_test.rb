require_relative 'minitest_helper.rb'
require_relative '../lib/active_record_monkeypatch.rb'
require_relative '../models/contribution'
require_relative '../models/section'
require_relative '../models/person'

class MonkeypatchTest < MiniTest::Spec
  describe "MonkeyPatch" do
    it "should allow ActiveRecord::Base to respond to 'subclasses'" do
      ActiveRecord::Base.must_respond_to(:subclasses)
    end
    
    it "should allow objects inheriting from ActiveRecord::Base to respond to 'subclasses'" do
      Contribution.must_respond_to(:subclasses)
    end
    
    describe "when calling self.subclass on ActiveRecord::Base" do
      it "should call the class method descendants" do
        ActiveRecord::Base.expects(:descendants)
        ActiveRecord::Base.subclasses
      end
    
      it "should return an array of classes that inherit from the class" do
        ActiveRecord::Base.subclasses.must_equal([Contribution, Section, Person])
      end
    end
  end
end