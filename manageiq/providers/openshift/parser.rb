require 'manageiq/providers/inventory'
require 'manageiq/providers/openshift/inventory_collections'

module ManageIQ
  module Providers
    module Openshift
      class Parser
        include InventoryCollections

        def initialize(ems_id)
          @ems_id      = ems_id
          @collections = initialize_inventory_collections
        end

        def parse(kube)
          get_nodes(kube)
          get_namespaces(kube)
          get_resource_quotas(kube)
          get_limit_ranges(kube)
          get_replication_controllers(kube)
          get_persistent_volume_claims(kube)
          get_persistent_volumes(kube)
          get_pods(kube)
          get_endpoints(kube)
          get_services(kube)
          get_component_statuses(kube)
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
            node_hash = parse_base_item(node)

            collection.build(node_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting nodes...Complete - Count [#{collection.to_a.count}]"
        end

        def get_namespaces(kube)
          collection = @collections[:container_projects]

          puts "#{self.class.name}##{__method__}: Collecting projects..."

          kube.get_namespaces.to_a.each do |ns|
            ns_hash = parse_base_item(ns)

            collection.build(ns_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting projects...Complete - Count [#{collection.to_a.count}]"
        end

        def get_resource_quotas(kube)
          collection = @collections[:container_quotas]

          puts "#{self.class.name}##{__method__}: Collecting quotas..."

          kube.get_resource_quotas.to_a.each do |quota|
            quota_hash = parse_base_item(quota)

            collection.build(quota_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting quotas...Complete - Count [#{collection.to_a.count}]"
        end

        def get_limit_ranges(kube)
          collection = @collections[:container_limits]

          puts "#{self.class.name}##{__method__}: Collecting limits..."

          kube.get_limit_ranges.to_a.each do |limit_range|
            range_hash = parse_base_item(limit_range)

            collection.build(range_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting limits...Complete - Count [#{collection.to_a.count}]"
        end

        def get_replication_controllers(kube)
          collection = @collections[:container_replicators]

          puts "#{self.class.name}##{__method__}: Collecting replicators..."

          kube.get_replication_controllers.to_a.each do |rc|
            rc_hash = parse_base_item(rc)

            collection.build(rc_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting replicators...Complete - Count [#{collection.to_a.count}]"
        end

        def get_persistent_volume_claims(kube)
          collection = @collections[:persistent_volume_claims]

          puts "#{self.class.name}##{__method__}: Collecting persistent volume claims..."

          kube.get_persistent_volume_claims.to_a.each do |pv_claim|
            pv_claim_hash = parse_base_item(pv_claim)

            collection.build(pv_claim_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting persistent volume claims...Complete - Count [#{collection.to_a.count}]"
        end

        def get_persistent_volumes(kube)
          collection = @collections[:persistent_volumes]

          puts "#{self.class.name}##{__method__}: Collecting persistent volumes..."

          kube.get_persistent_volumes.to_a.each do |pv|
            pv_hash = parse_base_item(pv)

            collection.build(pv_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting persistent volumes...Complete - Count [#{collection.to_a.count}]"
        end

        def get_pods(kube)
          collection = @collections[:container_groups]

          puts "#{self.class.name}##{__method__}: Collecting groups..."

          kube.get_pods.to_a.each do |pod|
            pod_hash = parse_base_item(pod).merge!(
              :container_node    => lazy_find_node(pod.spec.nodeName),
              :container_project => lazy_find_project(pod.metadata["table"][:namespace]),
            )

            collection.build(pod_hash)

            unless pod.status.nil? || pod.status.containerStatuses.nil?
              pod.status.containerStatuses.each do |cn|
                parse_container(cn, pod.metadata.uid)
              end
            end
          end

          puts "#{self.class.name}##{__method__}: Collecting groups...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_container(container, pod_id)
          collection = @collections[:containers]

          container_hash = {
            :ems_ref => "#{pod_id}_#{container.name}_#{container.image}",
          }

          collection.build(container_hash)
        end

        def get_endpoints(kube)
          kube.get_endpoints.to_a.each do |endpoint|
          end
        end

        def get_services(kube)
          collection = @collections[:container_services]

          puts "#{self.class.name}##{__method__}: Collecting services..."

          kube.get_services.to_a.each do |service|
            service_hash = parse_base_item(service)

            collection.build(service_hash)
          end

          puts "#{self.class.name}##{__method__}: Collecting services...Complete - Count [#{collection.to_a.count}]"
        end

        def get_component_statuses(kube)
          collection = @collections[:container_component_statuses]

          puts "#{self.class.name}##{__method__}: Collecting statuses..."

          kube.get_component_statuses.to_a.each do |component_status|
            collection.build(
              parse_base_item(component_status)
            )
          end

          puts "#{self.class.name}##{__method__}: Collecting statuses...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_base_item(item)
          {
            :ems_ref          => item.metadata.uid,
            :name             => item.metadata.name,
            :ems_created_on   => item.metadata.creationTimestamp,
            :resource_version => item.metadata.resourceVersion
          }
        end

        def lazy_find_project(project)
          return if project.nil?

          @collections[:container_projects].lazy_find(project)
        end

        def lazy_find_node(node_name)
          return if node_name.nil?

          @collections[:container_nodes].lazy_find(node_name)
        end
      end
    end
  end
end
