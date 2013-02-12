require_relative '../minitest_helper.rb'
require_relative '../../models/contribution.rb'

class ContributionTest < MiniTest::Spec
  describe Contribution do
    describe "in general" do
      test_contribution = Contribution.new(
        {:sitting_type => "HouseOfCommonsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor",
         })
         
      it "should set the shared attributes correctly" do
        test_contribution.year.must_equal(1805)
        test_contribution.century.must_equal(19)
        test_contribution.decade.must_equal(1800)
      end
      
      it "should return nil for all speaker-related methods if there is no speaker" do
        test_contribution.speaker_slug.must_equal(nil)
        test_contribution.speaker_name.must_equal(nil)
      end
      
      it "should respond to the acts_as_present_on_date methods" do
        Contribution.must_respond_to(:present_dates_in_interval)
      end
    end
    
    describe "when given a contribution with a speaker" do
      person = Person.new(
        {:honorific => "Mr",
         :name => "Jim Hacker",
         :slug => "mr-jim-hacker"
        })
      
      test_contribution = Contribution.new(
        {:sitting_type => "HouseOfCommonsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor",
         :person => person
         })
      
      it "should correctly respond to the speaker-related methods" do
        test_contribution.speaker_slug.must_equal("mr-jim-hacker")
        test_contribution.speaker_name.must_equal("Mr Jim Hacker")
      end
    end
    
    describe "when given a House of Commons Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "HouseOfCommonsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Commons")
        test_contribution.section_link.must_equal("commons")
        test_contribution.url.must_equal("commons/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Westminster Hall Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "WestminsterHallSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Westminster Hall")
        test_contribution.section_link.must_equal("westminster_hall")
        test_contribution.url.must_equal("westminster_hall/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Commons Written Answers Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "CommonsWrittenAnswersSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Written Answers")
        test_contribution.section_link.must_equal("written_answers")
        test_contribution.url.must_equal("written_answers/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Commons Written Statements Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "CommonsWrittenStatementsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Written Statements")
        test_contribution.section_link.must_equal("written_statements")
        test_contribution.url.must_equal("written_statements/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a House of Lords Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "HouseOfLordsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
         
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Lords")
        test_contribution.section_link.must_equal("lords")
        test_contribution.url.must_equal("lords/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Grand Committee Report Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "GrandCommitteeReportSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
         
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Grand Committee report")
        test_contribution.section_link.must_equal("grand_committee_report")
        test_contribution.url.must_equal("grand_committee_report/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Lords Report Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "HouseofLordsReport",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
         
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Lords Reports")
        test_contribution.section_link.must_equal("lords_reports")
        test_contribution.url.must_equal("lords_reports/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Lords Written Answers Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "LordsWrittenAnswersSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Written Answers")
        test_contribution.section_link.must_equal("written_answers")
        test_contribution.url.must_equal("written_answers/1805/nov/10/test#anchor")
      end
    end
    
    describe "when given a Lords Written Statements Sitting" do
      test_contribution = Contribution.new(
        {:sitting_type => "LordsWrittenStatementsSitting",
         :date => Date.parse("1805-11-10"),
         :slug => "test",
         :anchor_id => "anchor"
         })
      
      it "should set the sitting-specific attributes correctly" do
        test_contribution.display_sitting_type.must_equal("Written Statements")
        test_contribution.section_link.must_equal("written_statements")
        test_contribution.url.must_equal("written_statements/1805/nov/10/test#anchor")
      end
    end
    
    describe "when determining whether there is any material for a given date range" do
      it "should search on the model's date field using the supplied start and end dates" do
        start_date = Date.parse("2002-10-01")
        end_date = Date.parse("2002-10-31")
        Contribution.expects(:find).with(:all, {:select => :date, :conditions => ["date >= ? and date <= ?", start_date, end_date]}).returns([])
        Contribution.present_dates_in_interval(start_date, end_date)
      end
    end
  end
end