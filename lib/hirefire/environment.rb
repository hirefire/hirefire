# encoding: utf-8

module HireFire
  module Environment
    autoload :Base,   'hirefire/environment/base'
    autoload :Heroku, 'hirefire/environment/heroku'
    autoload :Local,  'hirefire/environment/local'
    autoload :Noop,   'hirefire/environment/noop'

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
    #  - hirefire_hire      ( invoked when a job gets queued )
    #  - environment.fire   ( invoked when a queued job gets destroyed )
    #  - environment.fire   ( invoked when a queued job gets updated unless the job didn't fail )
    #
    # The Resque classes get their hooks injected from the HireFire::Initializer#initialize! method
    #
    # @param (Class) base This is the class in which this module will be included
    def self.included(base)
      base.send :extend, HireFire::Environment::ClassMethods

      ##
      # Only implement these hooks for Delayed::Job backends
      if base.name =~ /Delayed::Backend::(ActiveRecord|Mongoid)::Job/
        base.send :extend, HireFire::Environment::DelayedJob::ClassMethods

        base.class_eval do
          after_create  'self.class.hirefire_hire'
          after_destroy 'self.class.environment.fire'
          after_update  'self.class.environment.fire',
            :unless => Proc.new { |job| job.failed_at.nil? }
        end
      elsif base.name == "Delayed::Backend::DataMapper::Job"
        base.send :extend, HireFire::Environment::DelayedJob::ClassMethods

        base.class_eval do
          after :create do
            self.class.hirefire_hire
          end
          after :destroy do
            self.class.environment.fire
          end
          after :update do
            self.class.environment.fire unless self.failed_at.nil?
          end
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
            ::Rails.env.production? ? 'Heroku' : 'Noop'
          end
        ).new
      end
    end

    ##
    # Delayed Job specific module
    module DelayedJob
      module ClassMethods

        ##
        # This method is an attempt to improve web-request throughput.
        #
        # A class method for Delayed::Job which first checks if any worker is currently
        # running by checking to see if there are any jobs locked by a worker. If there aren't
        # any jobs locked by a worker there is a high chance that there aren't any workers running.
        # If this is the case, then we sure also invoke the 'self.class.environment.hire' method
        #
        # Another check is to see if there is only 1 job (which is the one that
        # was just added before this callback invoked). If this is the case
        # then it's very likely there aren't any workers running and we should
        # invoke the 'self.class.environment.hire' method to make sure this is the case.
        #
        # @return [nil]
        def hirefire_hire
          delayed_job = ::Delayed::Job.new
          if delayed_job.working == 0 \
          or delayed_job.jobs    == 1
            environment.hire
          end
        end
      end
    end

  end
end
