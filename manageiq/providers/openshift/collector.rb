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
          @kafka    = Kafka.new(seed_brokers: ["localhost:9092"], client_id: "miq-collector")
        end

        def run
          event_stream = kafka_event_consumer

          event_stream.each_message do |event|
            puts "#{self.class.name}##{__method__}: Received event: #{event.value}"

            refresh
          end
        end

        private
        
        def refresh
          puts "#{self.class.name}##{__method__}: Refreshing targets..."

          conn = connect
          inventory_stream = kafka_inventory_producer

          inv = parse_inventory(conn)

          publish_inventory(inventory_stream, inv)

          puts "#{self.class.name}##{__method__}: Refreshing targets...Complete"
        end

        def connect
          Kubeclient::Client.new(
            URI::HTTPS.build(:host => @hostname, :port => @port, :path => ''),
            'v1',
            :ssl_options => Kubeclient::Client::DEFAULT_SSL_OPTIONS.merge(verify_ssl:  OpenSSL::SSL::VERIFY_NONE),
            :auth_options => {
              :bearer_token => @token
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

        def parse_inventory(kube)
          puts "#{self.class.name}##{__method__}: Parsing inventory..."

          parser = ManageIQ::Providers::Openshift::Parser.new(@ems_id)
          parser.parse(kube)
          inventory = parser.inventory

          puts "#{self.class.name}##{__method__}: Parsing inventory...Complete"

          inventory.collect { |ic| ic.to_raw_data }.to_yaml
        end

        def publish_inventory(stream, inventory)
          stream.produce(inventory, topic: "inventory")
          stream.deliver_messages
        end
      end
    end
  end
end

