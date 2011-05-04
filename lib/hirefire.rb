# encoding: utf-8

module HireFire
  autoload :Configuration, 'hirefire/configuration'
  autoload :Environment,   'hirefire/environment'
  autoload :Initializer,   'hirefire/initializer'
  autoload :Backend,       'hirefire/backend'
  autoload :Logger,        'hirefire/logger'
  autoload :Version,       'hirefire/version'

  class << self
    
    attr_writer :configuration
    
    ##
    # This method is used to configure HireFire
    #
    # @yield [config] the instance of HireFire::Configuration class
    # @yieldparam [Fixnum] max_workers default: 1 (set at least 1)
    # @yieldparam [Array] job_worker_ratio default: see example
    # @yieldparam [Symbol, nil] environment (:heroku, :local, :noop or nil) - default: nil
    #
    # @note Every param has it's own defaults. It's best to leave the environment param at "nil".
    #   When environment is set to "nil", it'll default to the :noop environment. This basically means
    #   that you have to run "rake jobs:work" yourself from the console to get the jobs running in development mode.
    #   In production, it'll automatically use :heroku if deployed to the Heroku platform.
    #
    # @example
    #   HireFire.configure do |config|
    #     config.environment      = nil
    #     config.max_workers      = 5
    #     config.min_workers      = 0
    #     config.job_worker_ratio = [
    #       { :jobs => 1,   :workers => 1 },
    #       { :jobs => 15,  :workers => 2 },
    #       { :jobs => 35,  :workers => 3 },
    #       { :jobs => 60,  :workers => 4 },
    #       { :jobs => 80,  :workers => 5 }
    #     ]
    #   end
    #
    # @return [nil]
    def configure
      yield(configuration); nil
    end

    ##
    # Instantiates a new HireFire::Configuration
    # instance and instance variable caches it
    def configuration
      @configuration ||= HireFire::Configuration.new
    end
    
  end

end

##
# If Ruby on Rails is detected, it'll automatically initialize HireFire
# so that the developer doesn't have to manually invoke it from an initializer file
#
# Users not using Ruby on Rails will have to run "HireFire::Initializer.initialize!"
# in their application manually, after loading the worker library (either "Delayed Job" or "Resque")
# and the desired mapper (ActiveRecord, Mongoid or Redis)
if defined?(Rails)
  if defined?(Rails::Railtie)
    require 'hirefire/railtie'
  else
    HireFire::Initializer.initialize!
  end
end

