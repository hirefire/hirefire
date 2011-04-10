# encoding: utf-8

module HireFire
  class Railtie < Rails::Railtie

    ##
    # Initializes HireFire for Delayed Job when
    # the Ruby on Rails web framework is done loading
    initializer :after_initialize do
      HireFire::Initializer.initialize!
    end

  end
end
