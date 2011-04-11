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

  end
end
