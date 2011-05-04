# encoding: utf-8

module HireFire
  module Backend
    autoload :DelayedJob, 'hirefire/backend/delayed_job'
    autoload :Resque,     'hirefire/backend/resque'

    ##
    # Load the correct module (ActiveRecord, Mongoid or Redis)
    # based on which worker and backends are loaded
    #
    # Currently supports:
    #  - Delayed Job with ActiveRecord and Mongoid
    #  - Resque with Redis
    #
    # @return [nil]
    def self.included(base)

      ##
      # Delayed Job specific backends
      if defined?(::Delayed)
        if defined?(::Delayed::Backend::ActiveRecord::Job)
          if defined?(::ActiveRecord::Relation)
            base.send(:include, HireFire::Backend::DelayedJob::ActiveRecord)
          else
            base.send(:include, HireFire::Backend::DelayedJob::ActiveRecord2)
          end
        end

        if defined?(::Delayed::Backend::Mongoid::Job)
          base.send(:include, HireFire::Backend::DelayedJob::Mongoid)
        end
      end

      ##
      # Resque specific backends
      if defined?(::Resque)
        base.send(:include, HireFire::Backend::Resque::Redis)
      end
    end

  end
end

