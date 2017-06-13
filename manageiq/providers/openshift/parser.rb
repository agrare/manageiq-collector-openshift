require 'byebug'
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
          parse_pods(kube)
        end

        def inventory
          collections_data = @inv_collections.map do |key, collection|
            {
              :name => key,
              :data => collection.to_raw_data
            }
          end.compact

          yaml = YAML.dump(collections_data)
        end

        private

        def parse_pods(kube)
          kube.get_pods.to_a.each do |pod|
            @inv_collections[:container_groups].build(
              :ems_ref => pod.metadata.uid,
              :name    => pod.metadata.name,
              :type    => 'ManageIQ::Providers::Openshift::ContainerManager::ContainerGroup',
            )
          end
        end
      end
    end
  end
end
