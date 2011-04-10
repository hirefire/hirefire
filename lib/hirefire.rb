# encoding: utf-8

module HireFire

  ##
  # HireFire constants
  LIB_PATH         = File.dirname(__FILE__)
  FREELANCER_PATH  = File.join(LIB_PATH,        'hirefire')
  ENVIRONMENT_PATH = File.join(FREELANCER_PATH, 'environment')
  BACKEND_PATH     = File.join(FREELANCER_PATH, 'backend')

  ##
  # HireFire namespace
  autoload :Configuration, File.join(FREELANCER_PATH, 'configuration')
  autoload :Environment,   File.join(FREELANCER_PATH, 'environment')
  autoload :Initializer,   File.join(FREELANCER_PATH, 'initializer')
  autoload :Backend,       File.join(FREELANCER_PATH, 'backend')
  autoload :Logger,        File.join(FREELANCER_PATH, 'logger')
  autoload :Version,       File.join(FREELANCER_PATH, 'version')

  ##
  # HireFire::Environment namespace
  module Environment
    autoload :Base,   File.join(ENVIRONMENT_PATH, 'base')
    autoload :Heroku, File.join(ENVIRONMENT_PATH, 'heroku')
    autoload :Local,  File.join(ENVIRONMENT_PATH, 'local')
    autoload :Noop,   File.join(ENVIRONMENT_PATH, 'noop')
  end

  ##
  # HireFire::Backend namespace
  module Backend
    autoload :ActiveRecord, File.join(BACKEND_PATH, 'active_record')
    autoload :Mongoid,      File.join(BACKEND_PATH, 'mongoid')
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
# in their application manually, after loading Delayed Job and the desired mapper (ActiveRecord or Mongoid)
if defined?(Rails)
  require File.join(HireFire::FREELANCER_PATH, 'railtie')
end
