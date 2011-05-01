# encoding: utf-8

module HireFire
  module Backend
    module Resque
      module Redis

        ##
        # Counts the amount of pending jobs in Redis
        #
        # Failed jobs are excluded because they are not listed as "pending"
        # and jobs cannot be scheduled for the future in Resque
        #
        # @return [Fixnum]
        def jobs
          ::Resque.info[:pending].to_i
        end

        ##
        # Counts the amount of workers
        #
        # @return [Fixnum]
        def workers
          ::Resque.info[:workers].to_i
        end

        ##
        # Counts the amount of jobs that are being processed by workers
        #
        # @return [Fixnum]
        def working
          ::Resque.info[:working].to_i
        end

      end
    end
  end
end
