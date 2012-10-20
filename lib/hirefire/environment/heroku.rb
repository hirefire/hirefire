# encoding: utf-8

require 'heroku-api'

module HireFire
  module Environment
    class Heroku < Base

      private

      def workers(amount = nil)

        app_name = HireFire.configuration.app_name
        puts "HIREFIRE FOR APP #{app_name}"

        if amount.nil?
          # return client.info(app_name)[:workers].to_i
          return client.get_ps(app_name).body.select {|p| p['process'] =~ /worker.[0-9]+/}.length
        end

        # client.set_workers(app_name], amount)
        return client.post_ps_scale(app_name, "worker", amount)

      rescue Exception
        HireFire::Logger.message("Worker query request failed with #{ $!.class.name } #{ $!.message }")
        nil
      end

      def client
        @client ||= ::Heroku::API.new # will pick up api_key from configs
      end

    end
  end
end
