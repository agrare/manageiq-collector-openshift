require 'yaml'
require 'kubeclient'
require 'manageiq/providers/openshift/parser'

module ManageIQ
  module Providers
    module Openshift
      class Collector

        def initialize(ems_id, hostname, port, token)
          @ems_id   = ems_id
          @hostname = hostname
          @port     = port
          @token    = token
        end

        def run
          kube = connect(@hostname, @port, @token)
          parser = ManageIQ::Providers::Openshift::Parser.new(@ems_id)
          parser.parse(kube)
          puts parser.inventory
        end

        private
        
        def connect(hostname, port, token)
          Kubeclient::Client.new(
            URI::HTTPS.build(:host => hostname, :port => port, :path => ''),
            'v1',
            :ssl_options => Kubeclient::Client::DEFAULT_SSL_OPTIONS.merge(verify_ssl:  OpenSSL::SSL::VERIFY_NONE),
            :auth_options => {
              :bearer_token => token
            }
          )
        end
      end
    end
  end
end

