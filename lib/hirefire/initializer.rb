# encoding: utf-8

module HireFire
  class Initializer

    ##
    # Loads the HireFire extension in to Delayed Job and
    # extends the Delayed Job "jobs:work" rake task command
    #
    # @return [nil]
    def self.initialize!
      ##
      # If DelayedJob is using ActiveRecord, then include
      # HireFire::Environment in to the ActiveRecord Delayed Job Backend
      if defined?(Delayed::Backend::ActiveRecord::Job)
        Delayed::Backend::ActiveRecord::Job.
        send(:include, HireFire::Environment).
        send(:include, HireFire::Backend)
      end

      ##
      # If DelayedJob is using Mongoid, then include
      # HireFire::Environment in to the Mongoid Delayed Job Backend
      if defined?(Delayed::Backend::Mongoid::Job)
        Delayed::Backend::Mongoid::Job.
        send(:include, HireFire::Environment).
        send(:include, HireFire::Backend)
      end

      ##
      # Load Delayed Job extension, this is the start
      # method that gets invoked when running "rake jobs:work"
      require File.dirname(__FILE__) + '/delayed_job_extension'
    end

  end
end
