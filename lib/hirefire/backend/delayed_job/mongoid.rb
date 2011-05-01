# encoding: utf-8

module HireFire
  module Backend
    module DelayedJob
      module Mongoid

        ##
        # Counts the amount of queued jobs in the database,
        # failed jobs and jobs scheduled for the future are excluded
        #
        # @return [Fixnum]
        def jobs
          ::Delayed::Job.where(
            :failed_at  => nil,
            :run_at.lte => Time.now
          ).count
        end

        ##
        # Counts the amount of jobs that are locked by a worker
        # There is no other performant way to determine the amount
        # of workers there currently are
        #
        # @return [Fixnum] the amount of (assumably working) workers
        def working
          ::Delayed::Job.
          where(:locked_by.ne => nil).count
        end

      end
    end
  end
end
