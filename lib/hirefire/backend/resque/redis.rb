# encoding: utf-8

module HireFire
  module Backend
    module Resque
      module Redis

        ##
        # Counts the amount of queued jobs in the database,
        # failed jobs and jobs scheduled for the future are excluded
        #
        # @return [Fixnum]
        def jobs
          ::Resque.info[:pending].to_i + ::Resque.info[:working].to_i
        end

      end
    end
  end
end
