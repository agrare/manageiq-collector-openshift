require 'manageiq/providers/inventory'
require 'manageiq/providers/openshift/inventory_collections'

module ManageIQ
  module Providers
    module Openshift
      class Parser
        include InventoryCollections

        def initialize(ems_id)
          @ems_id          = ems_id
          @inv_collections = initialize_inventory_collections(ems_id)
        end

        def parse(kube)
          parse_nodes(kube)
          parse_pods(kube)
          parse_namespaces(kube)
        end

        def inventory
          @inv_collections.values
        end

        private

        def parse_nodes(kube)
          collection = @inv_collections[:container_nodes]

          puts "#{self.class.name}##{__method__}: Collecting nodes..."

          kube.get_nodes.to_a.each do |node|
            collection.build(
              :ems_ref => node.metadata.uid,
              :name    => node.metadata.name,
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting nodes...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_pods(kube)
          collection = @inv_collections[:container_groups]

          puts "#{self.class.name}##{__method__}: Collecting pods..."

          kube.get_pods.to_a.each do |pod|
            collection.build(
              :ems_ref => pod.metadata.uid,
              :name    => pod.metadata.name,
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting pods...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_namespaces(kube)
          collection = @inv_collections[:container_projects]

          puts "#{self.class.name}##{__method__}: Collecting projects..."

          kube.get_namespaces.to_a.each do |ns|
            collection.build(
              :ems_ref => ns.metadata.uid,
              :name    => ns.metadata.name,
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting projects...Complete - Count [#{collection.to_a.count}]"
        end
      end
    end
  end
end
