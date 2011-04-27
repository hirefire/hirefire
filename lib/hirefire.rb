# encoding: utf-8

module HireFire

  ##
  # HireFire constants
  LIB_PATH         = File.dirname(__FILE__)
  HIREFIRE_PATH    = File.join(LIB_PATH,      'hirefire')
  ENVIRONMENT_PATH = File.join(HIREFIRE_PATH, 'environment')
  BACKEND_PATH     = File.join(HIREFIRE_PATH, 'backend')
  WORKERS_PATH     = File.join(HIREFIRE_PATH, 'workers')

  ##
  # HireFire namespace
  autoload :Configuration, File.join(HIREFIRE_PATH, 'configuration')
  autoload :Environment,   File.join(HIREFIRE_PATH, 'environment')
  autoload :Initializer,   File.join(HIREFIRE_PATH, 'initializer')
  autoload :Backend,       File.join(HIREFIRE_PATH, 'backend')
  autoload :Logger,        File.join(HIREFIRE_PATH, 'logger')
  autoload :Version,       File.join(HIREFIRE_PATH, 'version')

  ##
  # HireFire::Environment namespace
  module Environment
    autoload :Base,   File.join(ENVIRONMENT_PATH, 'base')
    autoload :Heroku, File.join(ENVIRONMENT_PATH, 'heroku')
    autoload :Local,  File.join(ENVIRONMENT_PATH, 'local')
    autoload :Noop,   File.join(ENVIRONMENT_PATH, 'noop')
  end

  ##
  # HireFire::Workers namespace
  module Workers
    autoload :DelayedJob, File.join(WORKERS_PATH, 'delayed_job')
    autoload :Resque,     File.join(WORKERS_PATH, 'resque')
  end

  ##
  # HireFire::Backend namespace
  module Backend
    DELAYED_JOB_PATH = File.join(BACKEND_PATH, 'delayed_job')
    RESQUE_PATH      = File.join(BACKEND_PATH, 'resque')

    ##
    # HireFire::Backend::DelayedJob namespace
    module DelayedJob
      autoload :ActiveRecord,     File.join(DELAYED_JOB_PATH, 'active_record')
      autoload :OldActiveRecord,  File.join(DELAYED_JOB_PATH, 'old_active_record')
      autoload :Mongoid,          File.join(DELAYED_JOB_PATH, 'mongoid')
    end

    ##
    # HireFire::Backend::Resque namespace
    module Resque
      autoload :Redis, File.join(RESQUE_PATH, 'redis')
    end
  end

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
  def self.configure
    yield(configuration); nil
  end

  ##
  # Instantiates a new HireFire::Configuration
  # instance and instance variable caches it
  def self.configuration
    @configuration ||= HireFire::Configuration.new
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
    require File.join(HireFire::HIREFIRE_PATH, 'railtie')
  else
    HireFire::Initializer.initialize!
  end
end

