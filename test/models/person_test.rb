require_relative '../minitest_helper.rb'
require_relative '../../models/person.rb'

class PersonTest < MiniTest::Spec
  describe Person do
    describe "when asked to find a partial match" do
      describe "in all cases" do
        it "should return an empty array if there are no matches" do
          result = Person.find_partial_matches("xyz")
          result.must_equal([])
        end
        
        it "should return an empty array if given a blank string" do
          result = Person.find_partial_matches("")
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
          
          result = Person.find_partial_matches("Cusack-Smith")
          result.first.name.must_equal("Thomas Cusack-Smith")
          result.size.must_equal(5)
          
          result = Person.find_partial_matches("Bickford-Smith")
          result.first.name.must_equal("William Bickford-Smith")
          result[1].lastname.must_equal("Buchanan-Smith")
          result.size.must_equal(5)
        end
        
        it "should find a double-barrelled surname correctly if a first name is supplied" do
          result = Person.find_partial_matches("Iain Duncan Smith")
          result[0].name.must_equal("Iain Duncan Smith")
          
          result = Person.find_partial_matches("Thomas Cusack-Smith")
          result[0].name.must_equal("Thomas Cusack-Smith")
        end
        
        #it's a like search so anything longer than this will probably 
        #be picked up by the "3 or more" code anyway...
        it "should cope with triple-barrelled names" do
          result = Person.find_partial_matches("Home-Drummond-Moray")
          result[0].name.must_equal("Henry Home-Drummond-Moray")
          
          result = Person.find_partial_matches("Henry Home-Drummond-Moray")
          result[0].name.must_equal("Henry Home-Drummond-Moray")
        end
        
        #...but we'll check just in case (thanks Wikipedia!)
        it "should manage to find Richard Temple-Nugent-Brydges-Chandos-Grenville" do
          result = Person.find_partial_matches("Richard Temple-Nugent-Brydges-Chandos-Grenville")
          result[0].name.must_equal("Richard Temple-Nugent-Brydges-Chandos-Grenville")
        end
        
        it "should attempt to use the first part of the name as a first name if other methods fail" do
          result = Person.find_partial_matches("Ernest Armstrong") #watching too much House of Cards
          result[0].name.must_equal("Ernest Armstrong")
          result[1].name.must_equal("Andrew Armstrong")
          
          result = Person.find_partial_matches("Selwyn Lloyd")
          result[0].name.must_equal("Selwyn Lloyd")
          result[1].name.must_equal("Anthony Lloyd")
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