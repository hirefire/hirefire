# encoding: utf-8

module HireFire
  module Backend
    module DelayedJob
      module DataMapper

        ##
        # Counts the amount of queued jobs in the database,
        # failed jobs are excluded from the sum
        #
        # @return [Fixnum] the amount of pending jobs
        def jobs
          ::Delayed::Job.count(:failed_at => nil, :run_at.lte => Time.now.utc)
        end

        ##
        # Counts the amount of jobs that are locked by a worker
        # There is no other performant way to determine the amount
        # of workers there currently are
        #
        # @return [Fixnum] the amount of (assumably working) workers
        def working
          ::Delayed::Job.count(:locked_by.not => nil)
        end

      end
    end
  end
end
