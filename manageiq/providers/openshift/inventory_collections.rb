module ManageIQ
  module Providers
    module Openshift
      module InventoryCollections
        def initialize_inventory_collections
          collections = {}

          collections[:container_groups] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerGroup",
          )

          collections[:container_nodes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerNode",
          )

          collections[:container_projects] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerProject",
          )

          collections
        end
      end
    end
  end
end
