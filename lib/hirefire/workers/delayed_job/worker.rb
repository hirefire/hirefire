# encoding: utf-8

##
# HireFire
# This is a HireFire modified version of
# the official Delayed::Worker class
module Delayed
  class Worker

    ##
    # @note
    #   This method gets invoked on heroku by the rake task "jobs:work"
    #
    #   This is basically the same method as the Delayed Job version,
    #   except for the following:
    #
    #   1. All ouput will now go through the HireFire::Logger.
    #   2. Invoke the ::Delayed::Job.environment.hire method at every loop
    #      to see whether we need to hire more workers so that we can delegate
    #      this task to the workers, rather than the web servers to improve web-throughput
    #      by avoiding any unnecessary API calls to Heroku.
    #      If there are any workers running, then the front end will never invoke API calls
    #      since the worker(s) can handle this itself.
    #   3. When HireFire cannot find any jobs to process it sends the "fire"
    #      signal to all workers, ending all the processes simultaneously. The reason
    #      we wait for all the processes to finish before sending the signal is because it'll
    #      otherwise interrupt workers and leave jobs unfinished.
    #
    def start
      HireFire::Logger.message "Starting job worker!"

      trap('TERM') { HireFire::Logger.message 'Exiting...'; $exit = true }
      trap('INT')  { HireFire::Logger.message 'Exiting...'; $exit = true }

      queued = Delayed::Job.new

      loop do
        ::Delayed::Job.environment.hire
        result = nil

        realtime = Benchmark.realtime do
          result = work_off
        end

        count = result.sum

        break if $exit

        if count.zero?
          sleep(1)
        else
          HireFire::Logger.message "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        ##
        # HireFire Hook
        # After the last job in the queue finishes processing, Delayed::Job.new.jobs (queued.jobs)
        # will return 0. This means that there aren't any more jobs to process for any of the workers.
        # If this is the case it'll command the current environment to fire all the hired workers
        # and then immediately break out of this infinite loop.
        if queued.jobs == 0
          break if Delayed::Job.environment.fire
        end

        break if $exit
      end

    ensure
      Delayed::Job.clear_locks!(name)
    end
  end
end
