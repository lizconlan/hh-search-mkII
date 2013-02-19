require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
end

require 'net/http'
require 'active_record'
require "./solr/configure/environment.rb"

namespace :solr do

  desc 'Starts Solr. Options accepted: PORT=XX'
  task :start do
    begin
      n = Net::HTTP.new('127.0.0.1', SOLR_PORT)
      n.request_head('/').value 
    
    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} in use" and return
    
    rescue Errno::ECONNREFUSED #not responding
      Dir.chdir(SOLR_PATH) do
        pid = fork do
          #STDERR.close
          exec "java -Dsolr.data.dir=solr/data -Djetty.port=#{SOLR_PORT} -jar start.jar"
        end
        sleep(5)
        File.open("#{SOLR_PATH}/tmp/search_pid", "w"){ |f| f << pid}
        puts "Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    end
  end
  
  desc 'Stops Solr'
  task :stop do
    fork do
      file_path = "#{SOLR_PATH}/tmp/search_pid"
      if File.exists?(file_path)
        File.open(file_path, "r") do |f| 
          pid = f.readline
          Process.kill('TERM', pid.to_i)
        end
        File.unlink(file_path)
        puts "Solr shutdown successfully."
      else
        puts "Solr is not running.  I haven't done anything."
      end
    end
  end
end