require 'active_record'
require_relative 'minitest_helper.rb'
require_relative '../models/person.rb'

class PersonTest < MiniTest::Spec
  describe Person do
    describe "when asked to find a partial match" do
      describe "in all cases" do
        it "should return an empty array if there are no matches" do
          result = Person.find_partial_matches("xyz")
          result.must_equal([])
        end
        
        it "should default to returning 5 results" do
          result = Person.find_partial_matches("Smith")
          result.size.must_equal(5)
        end
        
        it "should return 4 results where only 4 results are valid" do
          result = Person.find_partial_matches("Marsd")
          result.size.must_equal(4)
        end
        
        it "should return more results if a higher limit is supplied" do
          result = Person.find_partial_matches("Smith", 10)
          result.size.must_equal(10)
        end
        
        it "should return fewer results if a lower limit is supplied" do
          result = Person.find_partial_matches("Smith", 2)
          result.size.must_equal(2)
        end
      end
      
      describe "when supplied a string with a space or a hyphen" do
        it "should first attempt to treat the name as double-barrelled" do
          result = Person.find_partial_matches("Duncan Smith")
          result.first.name.must_equal("Iain Duncan Smith")
          result.size.must_equal(5)
          result[1].lastname.must_equal("Bickford-Smith")
          
          result = Person.find_partial_matches("Bickford-Smith")
          result.first.name.must_equal("William Bickford-Smith")
          result[1].lastname.must_equal("Buchanan-Smith")
          result.size.must_equal(5)
        end
        
        it "should use the last part of the name as a fallback option" do
          result = Person.find_partial_matches("Betty Boothroyd")
          result.size.must_equal(1)
          result.first.name.must_equal("Betty Boothroyd")
        end
      end
    end
  end
end