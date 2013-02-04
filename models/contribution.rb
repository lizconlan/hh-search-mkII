# encoding: utf-8

require 'acts_as_solr'
require './lib/search_results.rb'

class Contribution < ActiveRecord::Base
  acts_as_solr :fields => [:solr_text, {:person_id => :facet},
                                       {:date => :facet},
                                       {:year => :facet},
                                       {:decade => :facet},
                                       {:sitting_type => :facet}],
               :facets => [:person_id, {:date => :date}, :year, :decade]
               
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
    
  def house
    case sitting_type
    when /Lords/, /GrandCommittee/
      "Lords"
    when /Commons/, /WestminsterHall/
      "Commons"
    end
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

  def cols
    column_range ? column_range.split(",").map{ |col| col } : []
  end

  def start_column
    cols.empty? ? nil : cols.first
  end
  
  def end_column
    cols.empty? ? nil : cols.last
  end
end