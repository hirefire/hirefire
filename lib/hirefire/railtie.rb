# encoding: utf-8

module HireFire
  class Railtie < Rails::Railtie

    ##
    # Initializes HireFire for either Delayed Job or Resque when
    # the Ruby on Rails web framework is done loading
    #
    # @note
    #   Either the Delayed Job, or the Resque worker library must be
    #   loaded BEFORE HireFire initializes, otherwise it'll be unable
    #   to detect the proper library and it will not work.
    initializer :after_initialize do
      HireFire::Initializer.initialize!
    end

    ##
    # Adds additional rake tasks to the Ruby on Rails environment
    #
    # @note
    #   In order for Resque to run on Heroku, it must have the 'rake jobs:work'
    #   rake task since that's what Heroku uses to start workers. When using
    #   Ruby on Rails automatically add the necessary default rake task for the user
    #
    # @note
    #   Delayed Job already has 'rake jobs:work' built in.
    #
    rake_tasks do

      ##
      # If Resque is loaded, then we load the Resque rake task
      # that'll allow Heroku to start up Resque as a worker
      if defined?(::Resque)
        require File.join(WORKERS_PATH, 'resque', 'tasks.rb')
      end
    end

  end
end
