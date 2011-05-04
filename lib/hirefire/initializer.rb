# encoding: utf-8

module HireFire
  class Initializer

    ##
    # Loads the HireFire extension in to the loaded worker library and
    # extends that library by injecting HireFire hooks in the proper locations.
    #
    # Currently it supports:
    #  - Delayed Job
    #    - ActiveRecord ORM
    #    - Mongoid ODM
    #  - Resque
    #    - Redis
    #
    # @note
    #   Either the Delayed Job, or the Resque worker library must be
    #   loaded BEFORE HireFire initializes, otherwise it'll be unable
    #   to detect the proper library and it will not work.
    #
    # @return [nil]
    def self.initialize!

      ##
      # Initialize Delayed::Job extensions if Delayed::Job is found
      if defined?(::Delayed)
        ##
        # If DelayedJob is using ActiveRecord, then include
        # HireFire::Environment in to the ActiveRecord Delayed Job Backend
        if defined?(::Delayed::Backend::ActiveRecord::Job)
          ::Delayed::Backend::ActiveRecord::Job.
          send(:include, HireFire::Environment).
          send(:include, HireFire::Backend)
        end

        ##
        # If DelayedJob is using Mongoid, then include
        # HireFire::Environment in to the Mongoid Delayed Job Backend
        if defined?(::Delayed::Backend::Mongoid::Job)
          ::Delayed::Backend::Mongoid::Job.
          send(:include, HireFire::Environment).
          send(:include, HireFire::Backend)
        end

        ##
        # Load Delayed Job extensions, this will patch Delayed::Worker
        # to implement the necessary hooks to invoke HireFire from
        require 'hirefire/workers/delayed_job'
      end

      ##
      # Initialize Resque extensions if Resque is found
      if defined?(::Resque)

        ##
        # Include the HireFire::Environment which will add an instance
        # of HireFire::Environment::(Heroku|Local|Noop) to the Resque::Job.environment class method
        #
        # Extend the Resque::Job class with the Resque::Job.jobs class method
        ::Resque::Job.
        send(:include, HireFire::Environment).
        send(:extend, HireFire::Backend::Resque::Redis)

        ##
        # Load Resque extensions, this will patch Resque, Resque::Job and Resque::Worker
        # to implement the necessary hooks to invoke HireFire from
        require 'hirefire/workers/resque'
      end
    end

  end
end

