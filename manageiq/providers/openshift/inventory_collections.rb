module ManageIQ
  module Providers
    module Openshift
      module InventoryCollections
        def initialize_inventory_collections(ems_id)
          @inv_collections = {}

          @inv_collections[:container_groups] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class    => "ContainerGroup",
            :builder_params => {:ems_id => ems_id},
            :association    => :container_groups,
          )

          @inv_collections[:container_nodes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class    => "ContainerNode",
            :builder_params => {:ems_id => ems_id},
            :association    => :container_nodes
          )

          @inv_collections[:container_projects] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class    => "ContainerProject",
            :builder_params => {:ems_id => ems_id},
            :association    => :container_projects
          )

          @inv_collections
        end
      end
    end
  end
end
