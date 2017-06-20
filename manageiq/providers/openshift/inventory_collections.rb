module ManageIQ
  module Providers
    module Openshift
      module InventoryCollections
        def initialize_inventory_collections
          collections = {}

          collections[:container_projects] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerProject"
          )

          collections[:container_quotas] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerQuota"
          )

          collections[:container_quota_items] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerQuotaItem"
          )

          collections[:container_limits] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerLimit"
          )

          collections[:container_limit_items] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerLimitItem"
          )

          collections[:container_nodes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerNode"
          )

          collections[:container_image_registries] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerImageRegistry"
          )

          collections[:container_images] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerImage"
          )

          collections[:container_groups] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerGroup",
          )

          collections[:container_definitions] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerDefinition",
          )

          collections[:container_volumes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerVolume",
          )

          collections[:containers] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "Container",
          )

          collections[:container_port_configs] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerPortConfig",
          )

          collections[:container_env_vars] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerPortConfig",
          )

          collections[:security_contexts] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "SecurityContext",
          )

          collections[:container_replicators] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerReplicator",
          )

          collections[:container_services] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerService",
          )

          collections[:container_service_port_configs] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerServicePortConfig",
          )

          collections[:container_routes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerRoute",
          )

          collections[:container_component_statuses] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerComponentStatus",
          )

          collections[:container_templates] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerTemplate",
          )

          collections[:container_template_parameters] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerTemplateParameter",
          )

          collections[:container_builds] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerBuild",
          )

          collections[:container_build_pods] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ContainerBuildPod",
          )

          collections[:persistent_volumes] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "PersistentVolume",
          )

          collections[:persistent_volume_claims] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "PersistentVolumeClaim",
          )

          collections
        end
      end
    end
  end
end
