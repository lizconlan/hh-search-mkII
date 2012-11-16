require 'active_record'
require_relative 'minitest_helper.rb'
require_relative '../models/hansard_reference.rb'

class HansardReferenceTest < MiniTest::Spec
  describe HansardReference do
    describe "when asked to look up a reference string" do
      describe "in all cases" do
        it "should return false if the string is not a Hansard reference" do
          result = HansardReference.lookup("this is not a reference")
          result.must_equal(false)
        end
        
        it "should return false if the reference string contains an invalid date" do
          result = HansardReference.lookup("HL Deb 31 Feb 1892 vol 28 c234")
          result.must_equal(false)
        end
        
        it "should return a HansardReference if the lookup is successful" do
          result = HansardReference.lookup("HC Deb 19 July 1982 vol 28 cc58-9w")
          result.must_be_instance_of(HansardReference)
        end
        
        it "should return a HansardReference with a match_type of 'not stored' if there is no matching sitting day" do
          #18th July 1982 was a Sunday so this shouldn't work
          partial_result = HansardReference.lookup("HC Deb 18 July 1982 vol 28")
          partial_result.must_be_instance_of(HansardReference)
          partial_result.match_type.must_equal("not stored")
          partial_result.date.must_equal(Date.parse("1982-07-18"))
          partial_result.volume.must_equal("28")
          partial_result.house.must_equal("Commons")
          
          full_result = HansardReference.lookup("HC Deb 18 July 1982 vol 28 cc58-9w")
          full_result.must_be_instance_of(HansardReference)
          full_result.match_type.must_equal("not stored")
          full_result.house.must_equal("Commons")
          full_result.column.must_equal("58w")
        end
      end
      
      describe "on success" do
        it "should set url and match_type" do
          result = HansardReference.lookup("HC Deb 19 July 1982 vol 28 cc58-9w")
          result.must_respond_to(:url)
          result.must_respond_to(:match_type)
          result.url.must_be_instance_of(String)
          result.match_type.must_be_instance_of(String)
        end
      
        it "should return a partial match for an incomplete reference" do
          result = HansardReference.lookup("HC Deb 19 July 1982 vol 28")
          result.url.must_equal("/sittings/1982/jul/19")
          result.match_type.must_equal("partial")
        end
        
        it "should return a full match for a complete reference" do
          result = HansardReference.lookup("HC Deb 19 July 1982 vol 28 cc58-9w")
          result.url.must_equal('/written_answers/1982/jul/19/laindon-common-bomb-disposal#column_58w')
          result.match_type.must_equal("full")
        end
        
        it "should return the first section in a column when only given a start_column reference" do
          result = HansardReference.lookup("HL Deb 15 January 1980 vol 404 c13")
          result.url.must_equal('/lords/1980/jan/15/furskins-bill-hl#column_13')
        end
        
        it "should correctly handle Lords Written Answers" do
          result = HansardReference.lookup("HL Deb 15 January 1980 vol 404 cc85-7WA")
          result.house.must_equal("Lords")
          result.sitting_type.must_equal("Written Answers")
          result.url.must_equal("/written_answers/1980/jan/15/entry-clearance-waiting-times#column_85wa")
        end
          
        it "should correctly handle Grand Committee Reports" do
          result = HansardReference.lookup("HL Deb 12 November 1997 vol 583 cc1-52GC")
          result.house.must_equal("Lords")
          result.sitting_type.must_equal("Grand Committee report")
          result.url.must_equal("/grand_committee_report/1997/nov/12/official-report-of-the-grand-committee#column_1gc")
        end
          
        it "should correctly handle Westminster Hall debates" do
          result = HansardReference.lookup("HC Deb 18 July 2001 vol 372 cc112-8WH")
          result.house.must_equal("Commons")
          result.sitting_type.must_equal("Westminster Hall")
          result.url.must_equal("/westminster_hall/2001/jul/18/operation-lancet#column_112wh")
        end
          
        it "should correctly handle Commons Written Statements" do
          result = HansardReference.lookup("HC Deb 08 March 2004 vol 418 c93WS")
          result.house.must_equal("Commons")
          result.sitting_type.must_equal("Written Statements")
          result.url.must_equal("/written_statements/2004/mar/08/police-information-technology#column_93ws")
        end
          
        it "should correctly handle Lords Written Statements" do
          result = HansardReference.lookup("HL Deb 08 March 2004 vol 658 cc63-4WS")
          result.house.must_equal("Lords")
          result.sitting_type.must_equal("Written Statements")
          result.url.must_equal("/written_statements/2004/mar/08/council-for-science-and-technology#column_63ws")
        end
          
        it "should correctly handle Commmons sittings" do
          result = HansardReference.lookup("HC Deb 18 November 1976 vol 919 cc1555-6")
          result.house.must_equal("Commons")
          result.sitting_type.must_equal("Commons sitting")
          result.url.must_equal("/commons/1976/nov/18/summer-time#column_1555")
        end
          
        it "should correctly handle Lords sittings" do
          result = HansardReference.lookup("HL Deb 20 April 1888 vol 325 c7")
          result.house.must_equal("Lords")
          result.sitting_type.must_equal("Lords sitting")
          result.url.must_equal("/lords/1888/apr/20/purchase-of-land-ireland-act-1885#column_7")
        end
        
        it "should correctly handle Lords reports" do
          result = HansardReference.lookup("Deb 19 July 1822 vol 7 cc1714-6")
          result.house.must_equal("Lords")
          result.sitting_type.must_equal("Lords reports")
          result.url.must_equal("/lords_reports/1822/jul/19/irish-insurrection-bill#column_1714")
        end
      end
    end
  end
end