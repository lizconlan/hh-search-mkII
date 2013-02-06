if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'test'
    add_group "Models", "models"
    add_group "Libraries", "lib"
    add_group "Helpers", "helpers"
  end
end

gem 'minitest'
require 'minitest/autorun'
require 'mocha/setup'
require 'turn'

require 'active_record'
dbconfig = YAML::load(File.open 'config/database.yml')
ActiveRecord::Base.establish_connection(dbconfig)

# require 'test/unit/ui/console/testrunner'
# 
# class Test::Unit::UI::Console::TestRunner
#   def guess_color_availability 
#     true 
#   end
# end

Turn.config do |c|
 # use one of output formats:
 # :outline  - turn's original case/test outline mode [default]
 # :progress - indicates progress with progress bar
 # :dotted   - test/unit's traditional dot-progress mode
 # :pretty  # - new pretty reporter
 # :marshal  - dump output as YAML (normal run mode only)
 # :cue      - interactive testing
 c.format  = :outline
 # turn on invoke/execute tracing, enable full backtrace
 #c.trace   = true
 # use humanized test names (works only with :outline format)
 #c.natural = true
end