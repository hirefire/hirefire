# encoding: utf-8

##
# HireFire
# This is a HireFire modified version of
# the official Resque::Worker class
module ::Resque
  class Worker
    def work(interval = 5.0, &block)
      interval = Float(interval)
      $0 = "resque: Starting"
      startup

      loop do
        break if shutdown?
        ::Resque::Job.environment.hire

        if not @paused and job = reserve
          log "got: #{job.inspect}"
          run_hook :before_fork, job
          working_on job

          if @child = fork(job)
            rand # Reseeding
            procline "Forked #{@child} at #{Time.now.to_i}"
            Process.wait
          else
            procline "Processing #{job.queue} since #{Time.now.to_i}"
            perform(job, &block)
            exit! unless @cant_fork
          end

          done_working
          @child = nil
        else

          ##
          # HireFire Hook
          # After the last job in the queue finishes processing, Resque::Job.jobs will return 0.
          # This means that there aren't any more jobs to process for any of the workers.
          # If this is the case it'll command the current environment to fire all the hired workers
          # and then immediately break out of this infinite loop.
          if (::Resque::Job.jobs + ::Resque::Job.working) == 0
            break if ::Resque::Job.environment.fire
          end

          sleep(interval)

        end
      end

    ensure
      unregister_worker
    end
  end
end
