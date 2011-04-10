# encoding: utf-8

module HireFire
  module Environment
    class Noop

      ##
      # Will invoke the #hire method, but won't actually do anything
      def hire
      end

      ##
      # Will invoke the #fire method, but won't actually do anything
      def fire
      end

    end
  end
end
