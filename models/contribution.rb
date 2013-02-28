# encoding: utf-8

require 'acts_as_solr'
require './lib/acts_as_solr_hacks.rb'
require './lib/present_on_date.rb'

class Contribution < ActiveRecord::Base
  include PresentOnDate
  
  acts_as_present_on_date :date
  
  acts_as_solr :fields => [:solr_text, {:person_id => :facet},
                                       {:date => :facet},
                                       {:sitting_type => :facet}],
               :facets => [:person_id, {:date => :date}]
               
  self.solr_configuration  =  { :type_field => "type_t",
                                :primary_key_field => "pk_i",
                                :default_boost => 1.0 }
  
  belongs_to :person
  
  def url
    "#{section_link}/#{date.year}/#{Date::ABBR_MONTHNAMES[date.month].downcase}/#{date.day}/#{slug}##{anchor_id}"
  end
  
  def speaker_slug
    person.slug if person
  end
  
  def speaker_name
    "#{person.honorific} #{person.name}" if person
  end
    
  def display_sitting_type
    case sitting_type
    when "CommonsWrittenAnswersSitting", "LordsWrittenAnswersSitting"
      "Written Answers"
    when "CommonsWrittenStatementsSitting", "LordsWrittenStatementsSitting"
      "Written Statements"
    when "HouseOfCommonsSitting"
      "Commons"
    when /LordsSitting/
      "Lords"
    when "HouseofLordsReport"
      "Lords Reports"
    when "GrandCommitteeReportSitting"
      "Grand Committee report"
    when "WestminsterHallSitting"
      "Westminster Hall"
    end
  end
  
  def section_link
    case sitting_type
    when "CommonsWrittenAnswersSitting", "LordsWrittenAnswersSitting"
      "written_answers"
    when "CommonsWrittenStatementsSitting", "LordsWrittenStatementsSitting"
      "written_statements"
    when "HouseOfCommonsSitting"
      "commons"
    when /LordsSitting/
      "lords"
    when "HouseofLordsReport"
      "lords_reports"
    when "GrandCommitteeReportSitting"
      "grand_committee_report"
    when "WestminsterHallSitting"
      "westminster_hall"
    end
  end
  
  def year
   date.year
  end
  
  def century
    date.century
  end
  
  def decade
   date.decade
  end
end