# encoding: utf-8

module HireFire
  module Backend

    ##
    # Load the correct module (ActiveRecord or Mongoid)
    # based on which Delayed::Backend has been loaded
    #
    # @return [nil]
    def self.included(base)
      if defined?(Delayed::Backend::ActiveRecord::Job)
        base.send(:include, ActiveRecord)
      end

      if defined?(Delayed::Backend::Mongoid::Job)
        base.send(:include, Mongoid)
      end
    end

  end
end
