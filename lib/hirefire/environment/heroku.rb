# encoding: utf-8

require 'heroku'

module HireFire
  module Environment
    class Heroku < Base

      private

      ##
      # Either retrieves the amount of currently running workers,
      # or set the amount of workers to a specific amount by providing a value
      #
      # @overload workers(amount = nil)
      #   @param [Fixnum] amount will tell heroku to run N workers
      #   @return [nil]
      # @overload workers(amount = nil)
      #   @param [nil] amount
      #   @return [Fixnum] will request the amount of currently running workers from Heroku
      def workers(amount = nil)

        #
        # Returns the amount of Delayed Job
        # workers that are currently running on Heroku
        if amount.nil?
          return client.info(ENV['APP_NAME'])[:workers].to_i
        end

        ##
        # Sets the amount of Delayed Job
        # workers that need to be running on Heroku
        client.set_workers(ENV['APP_NAME'], amount)

      rescue RestClient::Exception
        # Heroku library uses rest-client, currently, and it is quite
        # possible to receive RestClient exceptions through the client.
        HireFire::Logger.message("Worker query request failed with #{ $!.class.name } #{ $!.message }")
        nil
      end

      ##
      # @return [Heroku::Client] instance of the heroku client
      def client
        @client ||= ::Heroku::Client.new(
          ENV['HIREFIRE_EMAIL'], ENV['HIREFIRE_PASSWORD']
        )
      end

    end
  end
end
