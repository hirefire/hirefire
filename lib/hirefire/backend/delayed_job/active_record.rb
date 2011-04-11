# encoding: utf-8

module HireFire
  module Backend
    module DelayedJob
      module ActiveRecord

        ##
        # Counts the amount of queued jobs in the database,
        # failed jobs are excluded from the sum
        #
        # @return [Fixnum]
        def jobs
          Delayed::Job.
          where(:failed_at => nil).
          where('run_at <= ?', Time.now).count
        end

      end
    end
  end
end
