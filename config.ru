#setup gem environment
require 'bundler'
Bundler.setup

require 'sprockets'
require File.dirname(__FILE__) + "/server"

set :logging, false
disable :run, :reload

map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/stylesheets'
  run environment
end

run Sinatra::Application