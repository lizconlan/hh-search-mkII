require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/parser_methods'

module ActsAsSolr #:nodoc:

  module ClassMethods
    
    def rebuild_solr_index(batch_size=0, upto=0, options={}, &finder)
      finder ||= lambda { |ar, options| ar.find(:all, options.merge({:order => self.primary_key})) }
      verbose = options[:verbose] || false 
      @last_timepoint = Time.now
      if batch_size > 0
        items_processed = 0
        limit = batch_size
        offset = options[:offset] || 0
        max_id = upto
        max_record_id = Contribution.count_by_sql("select max(id) as id from contributions")
        max_id = max_record_id if max_record_id < max_id
        begin
          
          items = finder.call(self, {:limit => limit, :offset => offset})
          
          log_time("finder finished", verbose)
        
          add_batch = items.collect { |content| content.to_solr_doc }
        
          log_time("docs converted to solr docs", verbose)
          
          begin 
            add_to_solr(items, add_batch, offset)
          rescue Timeout::Error  
            puts "Timed out, continuing anyway."
          end

          if items.last 
            last_id = items.last.id
            log_time("batch added - first id #{items.first.id}, last id : #{last_id}", verbose)
          end
    
          items_processed += items.size
          logger.debug "#{items_processed.to_i} items for #{self.name} have been batch added to index."
          offset += limit
        end while max_id > offset
      else
        items = finder.call(self, {})
        items.each { |content| content.solr_save }
        items_processed = items.size
      end
      begin 
        puts "committing"
        solr_commit
      rescue Timeout::Error  
        puts "Timed out, continuing anyway."
      end
      logger.debug items_processed > 0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
    end
    
    def add_to_solr(items, add_batch, offset)
      if items.size > 0
        solr_add add_batch
      end
    
      if offset.remainder(10000) == 0
        puts "committing"
        solr_commit
      end
    
    end
  
    def log_time(message, verbose)
      elapsed_time = Time.now - @last_timepoint
      puts (elapsed_time.to_s + ": " + message) if verbose
      @last_timepoint = Time.now
    end
  
  end
end