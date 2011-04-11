# encoding: utf-8

module HireFire
  module Environment
    class Base

      ##
      # Include HireFire::Backend helpers
      include HireFire::Backend

      ##
      # This method gets invoked when a new job has been queued
      #
      # Iterates through the default (or user-defined) job/worker ratio until
      # it finds a match for the for the current situation (see example).
      #
      # @example
      #   # Say we have 40 queued jobs, and we configured our job/worker ratio like so:
      #
      #   HireFire.configure do |config|
      #     config.max_workers      = 5
      #     config.job_worker_ratio = [
      #       { :jobs => 1,   :workers => 1 },
      #       { :jobs => 15,  :workers => 2 },
      #       { :jobs => 35,  :workers => 3 },
      #       { :jobs => 60,  :workers => 4 },
      #       { :jobs => 80,  :workers => 5 }
      #     ]
      #   end
      #
      #   # It'll match at { :jobs => 35, :workers => 3 }, (35 jobs or more: hire 3 workers)
      #   # meaning that it'll ensure there are 3 workers running.
      #
      #   # If there were already were 3 workers, it'll leave it as is.
      #   
      #   # Alternatively, you can use a more functional syntax, which works in the same way.
      #   
      #   HireFire.configure do |config|
      #     config.max_workers = 5
      #     config.job_worker_ratio = [
      #       { :when => lambda {|jobs| jobs < 15 }, :workers => 1 },
      #       { :when => lambda {|jobs| jobs < 35 }, :workers => 2 },
      #       { :when => lambda {|jobs| jobs < 60 }, :workers => 3 },
      #       { :when => lambda {|jobs| jobs < 80 }, :workers => 4 }
      #     ]
      #   end
      #   
      #   # If there were more than 3 workers running (say, 4 or 5), it will NOT reduce
      #   # the number. This is because when you reduce the number of workers, you cannot
      #   # tell which worker Heroku will shut down, meaning you might interrupt a worker
      #   # that's currently working, causing the job to fail. Also, consider the fact that
      #   # there are, for example, 35 jobs still to be picked up, so the more workers,
      #   # the faster it processes. You aren't even paying more because it doesn't matter whether
      #   # you have 1 worker, or 5 workers processing jobs, because workers are pro-rated to the second.
      #   # So basically 5 workers would cost 5 times more, but will also process 5 times faster.
      #
      #   # Once all jobs finished processing (e.g. Delayed::Job.jobs == 0), HireFire will invoke a signal
      #   # which will set the workers back to 0 and shuts down all the workers simultaneously.
      #
      # @return [nil]
      def hire
        jobs_count    = jobs
        workers_count = workers
        to_hire = false
        
        ratio.each do |ratio|
          if ratio[:when].respond_to? :call
            # If the function is true (EG: jobs_count (25) < 35) and you only 
            # have one worker (workers_count (1) < workers ratio (2)), increase
            # the number of workers available.
            if ratio[:when].call(jobs_count) and workers_count < ratio[:workers] and max_workers >= ratio[:workers]
              log_and_hire(ratio[:workers])
              
              break
            end
            
          else
            # Standard integer (non-functional format)
            if jobs_count >= ratio[:jobs] and max_workers >= ratio[:workers]
              if not workers_count == ratio[:workers]
                log_and_hire(ratio[:workers])
              end
              
              break
            end
            
          end
        end
        
        # Finally, given a functional style ratio list and none have matched,
        # assume that there is a massive queue of jobs and max_workers is necessary.
        if ratio[:when].respond_to? :call and ratio.last[:when].call(jobs_count) === false
          workers(max_workers)
        end
      end

      ##
      # This method gets invoked when a job is either "destroyed"
      # or "updated, unless the job didn't fail"
      #
      # If there are workers active, but there are no more pending jobs,
      # then fire all the workers
      #
      # @return [nil]
      def fire
        if jobs == 0 and workers > 0
          Logger.message("All queued jobs have been processed. Firing all workers.")
          workers(0)
        end
      end

      private
      
      ##
      # Helper method for hire that logs the hiring of more workers, then hires those workers.
      #
      # @return [nil]
      def log_and_hire(some_workers)
        Logger.message("Hiring more workers so we have #{ ratio[:workers] } in total.")
        workers(some_workers)
      end
      
      ##
      # Wrapper method for HireFire.configuration
      # Returns the max amount of workers that may run concurrently
      #
      # @return [Fixnum] the max amount of workers that are allowed to run concurrently
      def max_workers
        HireFire.configuration.max_workers
      end

      ##
      # Wrapper method for HireFire.configuration
      # Returns the job/worker ratio array (in reversed order)
      #
      # @return [Array] the array of hashes containing the job/worker ratio (in reversed order)
      def ratio
        HireFire.configuration.job_worker_ratio.reverse
      end

    end
  end
end
