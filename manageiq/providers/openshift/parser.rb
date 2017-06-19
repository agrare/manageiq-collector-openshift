require 'manageiq/providers/inventory'
require 'manageiq/providers/openshift/inventory_collections'

module ManageIQ
  module Providers
    module Openshift
      class Parser
        include InventoryCollections

        def initialize(ems_id)
          @ems_id          = ems_id
          @collections = initialize_inventory_collections
        end

        def parse(kube)
          get_nodes(kube)
          get_pods(kube)
          get_namespaces(kube)
        end

        def inventory
          @collections
        end

        def inventory_yaml
          collections = inventory.map do |key, collection|
            next if collection.data.blank? && collection.manager_uuids.blank? && collection.all_manager_uuids.nil?

            {
              :name              => key,
              :manager_uuids     => collection.manager_uuids,
              :all_manager_uuids => collection.all_manager_uuids,
              :data              => collection.to_raw_data
            }
          end.compact

          inv = YAML.dump({
            :ems_id      => @ems_id,
            :class       => "ManageIQ::Providers::Kubernetes::Inventory::Persister::ContainerManager",
            :collections => collections
          })
        end
        private

        def get_nodes(kube)
          collection = @collections[:container_nodes]

          puts "#{self.class.name}##{__method__}: Collecting nodes..."

          kube.get_nodes.to_a.each do |node|
            collection.build(
              :ems_ref => node.metadata.uid,
              :name    => node.metadata.name,
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting nodes...Complete - Count [#{collection.to_a.count}]"
        end

        def get_pods(kube)
          collection = @collections[:container_groups]

          puts "#{self.class.name}##{__method__}: Collecting pods..."

          kube.get_pods.to_a.each do |pod|
            collection.build(
              :ems_ref => pod.metadata.uid,
              :name    => pod.metadata.name,
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting pods...Complete - Count [#{collection.to_a.count}]"
        end

        def get_namespaces(kube)
          collection = @collections[:container_projects]

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
