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

      end
    end
  end
end
