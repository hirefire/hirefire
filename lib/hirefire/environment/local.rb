# encoding: utf-8

require 'rush'

module HireFire
  module Environment
    class Local < Base

      private

      ##
      # Either retrieve the amount of currently running workers,
      # or set the amount of workers to a specific amount by providing a value
      #
      # @overload workers(amount = nil)
      #   @param [Fixnum] amount will tell the local machine to run N workers
      #   @return [nil]
      # @overload workers(amount = nil)
      #   @param [nil] amount
      #   @return [Fixnum] will request the amount of currently running workers from the local machine
      def workers(amount = nil)

        ##
        # Returns the amount of Delayed Job workers that are currently
        # running on the local machine if amount is nil
        if amount.nil?
          return Rush::Box.new.processes.filter(
            :cmdline => /rake jobs:work WORKER=HIREFIRE/
          ).size
        end

        ##
        # Fire workers
        #
        # If the amount of workers required is set to 0
        # then we fire all the workers and we return
        #
        # The worker that finished the last job will go ahead and
        # kill all the other (if any) workers first, and then kill itself afterwards
        if amount == 0

          ##
          # Gather process ids from all HireFire workers
          pids = Rush::Box.new.processes.filter(
            :cmdline => /rake jobs:work WORKER=HIREFIRE/
          ).map(&:pid)

          ##
          # Instantiate a new local (shell) connection
          shell = Rush::Connection::Local.new

          ##
          # Kill all Freelance workers,
          # except the one that's doing the killing
          (pids - [Rush.my_process.pid]).each do |pid|
            shell.kill_process(pid)
          end

          ##
          # Kill the last Freelance worker (self)
          Logger.message("There are now #{ amount } workers.")
          shell.kill_process(Rush.my_process.pid)
          return
        end

        ##
        # Hire workers
        #
        # If the amount of workers required is greater than
        # the amount of workers already working, then hire the
        # additional amount of workers required
        workers_count = workers
        if amount > workers_count
          (amount - workers_count).times do
            Rush::Box.new[Rails.root].bash(
              'rake jobs:work WORKER=HIREFIRE', :background => true
            )
          end
        end
      end

    end
  end
end
