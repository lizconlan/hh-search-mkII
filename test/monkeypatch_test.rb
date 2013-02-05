require_relative 'minitest_helper.rb'
require_relative '../lib/active_record_monkeypatch.rb'
require_relative '../models/contribution'

class MonkeypatchTest < MiniTest::Spec
  describe "MonkeyPatch" do
    it "should allow ActiveRecord to respond to 'subclasses'" do
      ActiveRecord::Base.must_respond_to(:subclasses)
    end
    
    it "should allow objects inheriting from ActiveRecord::Base to respond to 'subclasses'" do
      Contribution.must_respond_to(:subclasses)
    end
  end
end