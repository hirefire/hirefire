# encoding: utf-8

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
    #   2. When HireFire cannot find any jobs to process it sends the "fire"
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
        # If there are no jobs currently queued,
        # and the worker is still running, it'll kill itself
        if queued.jobs == 0
          Delayed::Job.environment.fire
        end

        break if $exit
      end

    ensure
      Delayed::Job.clear_locks!(name)
    end
  end
end
