# encoding: utf-8

module HireFire
  module Backend
    module DelayedJob
      module ActiveRecord2

        ##
        # Counts the amount of queued jobs in the database,
        # failed jobs are excluded from the sum
        #
        # @return [Fixnum] the amount of pending jobs
        def jobs
          ::Delayed::Job.all(
            :conditions => ['failed_at IS NULL and run_at <= ?', Time.now.utc]
          ).count
        end

        ##
        # Counts the amount of jobs that are locked by a worker
        # There is no other performant way to determine the amount
        # of workers there currently are
        #
        # @return [Fixnum] the amount of (assumably working) workers
        def working
          ::Delayed::Job.all(
            :conditions => 'locked_by IS NOT NULL'
          ).count
        end

      end
    end
  end
end

