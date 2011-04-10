# encoding: utf-8

module HireFire
  module Environment

    ##
    # This gets included in to the Delayed::Backend::(ActiveRecord|Mongoid)::Job
    # classes and will add the necessary hooks (after_create, after_destroy and after_update)
    # to spawn or kill Delayed Job worker processes on either Heroku or your local machine
    #
    # @param (Class) base This is the class in which this module will be included
    def self.included(base)
      base.send :extend, ClassMethods
      base.class_eval do
        after_create  'self.class.environment.hire'
        after_destroy 'self.class.environment.fire'
        after_update  'self.class.environment.fire',
          :unless => Proc.new { |job| job.failed_at.nil? }
      end

      Logger.message("Successfully hooked in to #{ base.name }!")
    end

    ##
    # Class methods that will be added to the Delayed::Job backend
    module ClassMethods

      ##
      # Returns the environment class method (for Delayed::Job ORM/ODM class)
      #
      # If HireFire.configuration.environment is nil (the default) then it'll
      # auto-detect which environment to run in (either Heroku or Local)
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
