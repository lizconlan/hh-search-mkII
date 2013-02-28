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

  desc 'Starts Solr. Options accepted: ENV=your_env, PORT=XX'
  task :start do
    env =  ENV['env'] || "development"
    begin
      n = Net::HTTP.new('127.0.0.1', SOLR_PORT)
      n.request_head('/').value 
    
    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} in use" and return
    
    rescue Errno::ECONNREFUSED #not responding
      Dir.chdir(SOLR_PATH) do
        pid = fork do
          #STDERR.close
          if env == "production"
            exec "java -Dsolr.data.dir=solr/data/#{env} -javaagent:../newrelic/newrelic.jar -Djetty.port=#{SOLR_PORT} -jar start.jar"
          else
            exec "java -Xms512M -Xmx2048M -Dsolr.data.dir=solr/data/#{env} -Djetty.port=#{SOLR_PORT} -jar start.jar"
          end
        end
        sleep(5)
        File.open("#{SOLR_PATH}/tmp/#{env}_pid", "w"){ |f| f << pid}
        puts "#{env} Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    end
  end
  
  desc 'Stops Solr. Options accepted: ENV=your_env'
  task :stop do
    env =  ENV['env'] || "development"
    fork do
      file_path = "#{SOLR_PATH}/tmp/#{env}_pid"
      if File.exists?(file_path)
        File.open(file_path, "r") do |f| 
          pid = f.readline
          Process.kill('TERM', pid.to_i)
        end
        File.unlink(file_path)
        puts "#{env} Solr shutdown successfully."
      else
        puts "#{env} Solr is not running.  I haven't done anything."
      end
    end
  end
end