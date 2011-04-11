# encoding: utf-8

module HireFire
  module Environment

    ##
    # This module gets included in either:
    #  - Delayed::Backend::ActiveRecord::Job
    #  - Delayed::Backend::Mongoid::Job
    #  - Resque::Job
    #
    # One of these classes will then be provided with an instance of one of the following:
    #  - HireFire::Environment::Heroku
    #  - HireFire::Environment::Local
    #  - HireFire::Environment::Noop
    #
    # This instance is stored in the Class.environment class method
    #
    # The Delayed Job classes receive 3 hooks:
    #  - environment.hire ( invoked when a job gets queued )
    #  - environment.fire ( invoked when a queued job gets destroyed )
    #  - environment.fire ( invoked when a queued job gets updated unless the job didn't fail )
    #
    # The Resque classes get their hooks injected from the HireFire::Initializer#initialize! method
    #
    # @param (Class) base This is the class in which this module will be included
    def self.included(base)
      base.send :extend, HireFire::Environment::ClassMethods

      ##
      # Only implement these hooks for Delayed::Job backends
      if base.name =~ /Delayed::Backend::(ActiveRecord|Mongoid)::Job/
        base.class_eval do
          after_create  'self.class.environment.hire'
          after_destroy 'self.class.environment.fire'
          after_update  'self.class.environment.fire',
            :unless => Proc.new { |job| job.failed_at.nil? }
        end
      end

      Logger.message("#{ base.name } detected!")
    end

    ##
    # Class methods that will be added to the
    # Delayed::Job and Resque::Job classes
    module ClassMethods

      ##
      # Returns the environment class method (containing an instance of the proper environment class)
      # for either Delayed::Job or Resque::Job
      #
      # If HireFire.configuration.environment is nil (the default) then it'll
      # auto-detect which environment to run in (either Heroku or Noop)
      #
      # If HireFire.configuration.environment isn't nil (explicitly set) then
      # it'll run in the specified environment (Heroku, Local or Noop)
      #
      # @return [HireFire::Environment::Heroku, HireFire::Environment::Local, HireFire::Environment::Noop]
      def environment
        @environment ||= HireFire::Environment.const_get(
          if environment = HireFire.configuration.environment
            environment.to_s.camelize
          else
            ENV.include?('HEROKU_UPID') ? 'Heroku' : 'Noop'
          end
        ).new
      end
    end

  end
end
