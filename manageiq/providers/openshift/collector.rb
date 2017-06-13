require 'kafka'
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

          logger = Logger.new(STDOUT, level: :info)
          @kafka = Kafka.new(seed_brokers: ["apache-kafka:9092"], client_id: "miq-collectors", logger: logger)
        end

        def run
          puts "#{self.class.name}##{__method__}: Connecting to #{@hostname}"

          kube = connect(@hostname, @port, @token)
          kafka_event_consumer.each_message do |event|
            refresh(kube, kafka_inventory_producer)
          end
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

        def kafka_event_consumer
          @kafka.consumer(group_id: "miq-collectors").tap do |consumer|
            consumer.subscribe("event", start_from_beginning: false)
          end
        end

        def kafka_inventory_producer
          @kafka.producer
        end

        def refresh(kube, inventory)
          puts "#{self.class.name}##{__method__}: Refreshing targets"

          parser = ManageIQ::Providers::Openshift::Parser.new(@ems_id)
          parser.parse(kube)
          puts parser.inventory

          puts "#{self.class.name}##{__method__}: Refreshing targets...Complete"
          STDOUT.flush
        end
      end
    end
  end
end

