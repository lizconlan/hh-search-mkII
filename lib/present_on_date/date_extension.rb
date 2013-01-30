# copied from: https://github.com/millbanksystems/hansard/blob/master/vendor/plugins/present_on_date/lib/date_extension.rb

# Adds has_material? method to date instances and material_dates_in_interval to
# Date class
class Date
  def material_dates_upto(end_date)
    all_material_dates_upto(end_date).uniq.sort
  end
  
  def material_dates_count_upto(end_date)
    dates = all_material_dates_upto(end_date)
    
    dates.inject({}) do |counts, d|
      counts[d] = 0 unless counts.has_key?(d)
      counts[d] = counts[d] + 1
      counts
    end
  end
  
  def has_material?
    material = false
    Date.active_record_models.each do |model|
      if model.respond_to? "present_on_date?".to_sym
        if model.present_on_date? self
          material = true
          break
        end
      end
    end
    material
  end
  
  def models_present
    models = []
    Date.active_record_models.each do |model|
      if model.respond_to? "present_on_date?".to_sym
        if model.present_on_date? self
          models << model
        end
      end
    end
    models
  end
  
  def first_and_last_of_month
    first = Date.civil(self.year, self.month, 1)
    if self.month == 12
      last = Date.civil(self.year + 1, 1, 1) - 1.day
    else
      last = Date.civil(self.year, self.month + 1, 1) - 1.day
    end
    [first, last]
  end
  
  def first_of_year
    Date.civil(self.year, 1, 1)
  end
  
  def last_of_year
    Date.civil(self.year, 12, 31)
  end
  
  def first_and_last_of_year
    [first_of_year, last_of_year]
  end
  
  def first_of_decade 
    first_year = (self.year.to_s[0...3]+'0').to_i
    Date.civil(first_year, 1, 1)
  end
  
  def last_of_decade
    Date.civil(first_of_decade.year+9, 12, 31)
  end
  
  def first_and_last_of_decade  
    [first_of_decade, last_of_decade]
  end
  
  def first_of_century
    first_digits = year.to_s[0...2]
    first_year_of_century = (first_digits+"00").to_i
    Date.civil(first_year_of_century)
  end
  
  def last_of_century
    Date.civil(first_of_century.year+99, 12, 31)
  end
  
  def first_and_last_of_century
    [first_of_century, last_of_century]
  end
  
  def get_interval_delimiters resolution, options
    if options[:start_date] and options[:end_date]
      return [options[:start_date], options[:end_date]]
    end 
    case resolution
      when :day;      first_and_last_of_month
      when :month;    first_and_last_of_year
      when :year;     first_and_last_of_decade
      when :decade;   first_and_last_of_century
    end
  end
  
  def decade_string
    year.to_s[0...3] + '0s'
  end
  
  def century_string
    "C#{century}"
  end
  
  def century_ordinal
    century.ordinalize
  end
  
  def century
    (year.to_s[0...2].to_i)+1
  end
      
  def Date.lower_resolution(resolution)
    if index = resolutions.index(resolution)
     return resolutions.at(resolutions.index(resolution)-1) if index > 0
    else
      resolutions.last
    end
  end
  
  def Date.higher_resolution(resolution)
    if index = resolutions.index(resolution)
      return resolutions.at(index+1)
    else
      resolutions.first
    end
  end
   
  def decade
    ((year/10)*10)
  end
  
  def Date.year_from_century_string century_string
    century_to_year(century_string[1..2].to_i)
  end
  
  def Date.first_of_century(century)
     Date.new(century_to_year(century))
  end
  
  def Date.century_to_year(century)
    ((century - 1).to_s + "00").to_i
  end
   
   
  private
    
    def Date.resolutions
      [:decade, :year, :month, :day]
    end
    
    def Date.active_record_models
      Dir.glob("#{RAILS_ROOT}/app/models/**/*rb").each do |m|
        Dependencies.require_or_load m
      end
      Object.subclasses_of(ActiveRecord::Base).select {|o| o.superclass == ActiveRecord::Base }
    end
    
    def all_material_dates_upto(end_date)
      dates = []
      Date.active_record_models.each do |model|
        if model.respond_to? "present_dates_in_interval".to_sym
          model_dates = model.present_dates_in_interval self, end_date
          dates += model_dates.map{|date| date.to_date} if model_dates
        end
      end
      dates
    end
end