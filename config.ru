#setup gem environment
require 'bundler'
Bundler.setup

require File.dirname(__FILE__) + "/server"

set :logging, false
disable :run, :reload

run Sinatra::Application