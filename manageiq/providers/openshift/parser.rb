require 'active_support/core_ext/object/try'

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
            collection.build(parse_node(node))
          end

          puts "#{self.class.name}##{__method__}: Collecting nodes...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_node(node)
          node_hash = parse_base_item(node).merge!(
            :type           => 'ManageIQ::Providers::Kubernetes::ContainerManager::ContainerNode',
            :identity_infra => node.spec.providerID,
            # TODO: labels, tags, lives_on_id, lives_on_type
          )

          if !node.status.nil? && !node.status.nodeInfo.nil?
            node_info = node.status.nodeInfo
            node_hash.merge!(
              :identity_machine           => node_info.machineID,
              :identity_system            => node_info.systemUUID,
              :container_runtime_version  => node_info.containerRuntimeVersion,
              :kubernetes_proxy_version   => node_info.kubeProxyVersion,
              :kubernetes_kubelet_version => node_info.kubeletVersion
            )
          end

          node_hash
        end

        def get_namespaces(kube)
          collection = @collections[:container_projects]

          puts "#{self.class.name}##{__method__}: Collecting projects..."

          kube.get_namespaces.to_a.each do |ns|
            collection.build(parse_namespace(ns))
          end

          puts "#{self.class.name}##{__method__}: Collecting projects...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_namespace(namespace)
          namespace_hash = parse_base_item(namespace)
          # TODO: labels, tags
          namespace_hash
        end

        def get_resource_quotas(kube)
          collection = @collections[:container_quotas]

          puts "#{self.class.name}##{__method__}: Collecting quotas..."

          kube.get_resource_quotas.to_a.each do |quota|
            collection.build(parse_resource_quota(quota))
          end

          puts "#{self.class.name}##{__method__}: Collecting quotas...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_resource_quota(quota)
          parse_base_item(quota).merge!(
            :container_project => lazy_find_project(quota.metadata["table"][:namespace])
            # TODO: container_quota_items
          )
        end

        def get_limit_ranges(kube)
          collection = @collections[:container_limits]

          puts "#{self.class.name}##{__method__}: Collecting limits..."

          kube.get_limit_ranges.to_a.each do |limit_range|
            collection.build(parse_limit_range(limit_range))
          end

          puts "#{self.class.name}##{__method__}: Collecting limits...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_limit_range(range)
          parse_base_item(range).merge!(
            :container_project => lazy_find_project(range.metadata["table"][:namespace])
            # TODO: container_limit_items
          )
        end

        def get_replication_controllers(kube)
          collection = @collections[:container_replicators]

          puts "#{self.class.name}##{__method__}: Collecting replicators..."

          kube.get_replication_controllers.to_a.each do |rc|
            collection.build(parse_replication_controller(rc))
          end

          puts "#{self.class.name}##{__method__}: Collecting replicators...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_replication_controller(rc)
          parse_base_item(rc).merge!(
            :container_project => lazy_find_project(rc.metadata["table"][:namespace]),
            :replicas          => rc.spec.replicas,
            :current_replicas  => rc.status.replicas,
            # TODO: labels, tags, selector_parts
          )
        end

        def get_persistent_volume_claims(kube)
          collection = @collections[:persistent_volume_claims]

          puts "#{self.class.name}##{__method__}: Collecting persistent volume claims..."

          kube.get_persistent_volume_claims.to_a.each do |pv_claim|
            collection.build(parse_persistent_volume_claim(pv_claim))
          end

          puts "#{self.class.name}##{__method__}: Collecting persistent volume claims...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_persistent_volume_claim(claim)
          parse_base_item(claim).merge!(
            :desired_access_modes => claim.spec.accessModes,
            :phase                => claim.status.phase,
            :actual_access_modes  => claim.status.accessModes,
            # TODO: capacity
          )
        end

        def get_persistent_volumes(kube)
          collection = @collections[:persistent_volumes]

          puts "#{self.class.name}##{__method__}: Collecting persistent volumes..."

          kube.get_persistent_volumes.to_a.each do |pv|
            collection.build(parse_persistent_volume(pv))
          end

          puts "#{self.class.name}##{__method__}: Collecting persistent volumes...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_persistent_volume(pv)
          parse_base_item(pv).merge!(
            :access_modes => pv.spec.accessModes.join(','),
            :reclaim_policy => pv.spec.persistentVolumeReclaimPolicy,
            :status_phase   => pv.status.phase,
            :status_message => pv.status.message,
            :status_reason  => pv.status.reason,
            :persistent_volume_claim => lazy_find_pv_claim(pv.spec.claimRef.namespace,
                                                           pv.spec.claimRef.name)
          )
        end

        def get_pods(kube)
          collection = @collections[:container_groups]

          puts "#{self.class.name}##{__method__}: Collecting groups..."

          kube.get_pods.to_a.each do |pod|
            collection.build(parse_pod(pod))

            pod.status.try(:containerStatuses).to_a.each do |cn|
              container_hash = parse_container(cn, pod.metadata.uid)
              @collections[:containers].build(container_hash)
            end
          end

          puts "#{self.class.name}##{__method__}: Collecting groups...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_pod(pod)
          build_pod_name = pod.metadata.try(:annotations).try("openshift.io/build.name".to_sym)

          parse_base_item(pod).merge!(
            :container_project   => lazy_find_project(pod.metadata["table"][:namespace]),
            :container_node      => lazy_find_node(pod.spec.nodeName),
            :restart_policy      => pod.spec.restartPolicy,
            :dns_policy          => pod.spec.dnsPolicy,
            :ipaddress           => pod.status.podIP,
            :phase               => pod.status.phase,
            :message             => pod.status.message,
            :reason              => pod.status.reason,
            :container_build_pod => lazy_find_build_pod(build_pod_name)
          )
        end

        def parse_container(container, pod_id)
          {
            :ems_ref => "#{pod_id}_#{container.name}_#{container.image}",
            :name    => container.name,
            :restart_count => container.restartCount,
            :backing_ref   => container.containerID,
          }
        end

        def get_endpoints(kube)
          kube.get_endpoints.to_a.each do |endpoint|
          end
        end

        def get_services(kube)
          collection = @collections[:container_services]

          puts "#{self.class.name}##{__method__}: Collecting services..."

          kube.get_services.to_a.each do |service|
            collection.build(parse_service(service))
          end

          puts "#{self.class.name}##{__method__}: Collecting services...Complete - Count [#{collection.to_a.count}]"
        end

        def parse_service(service)
          service_hash = parse_base_item(service).merge!(
            :container_project => lazy_find_project(service.metadata["table"][:namespace]),
            :portal_ip         => service.spec.clusterIP,
            :session_affinity  => service.spec.sessionAffinity,
            :service_type      => service.spec.type,
            # TODO: labels, tags, selector_parts, container_groups
          )

          if service_hash[:ems_ref].nil?
            service_hash[:ems_ref] = "#{service_hash[:namespace]}_#{service_hash[:name]}"
          end

          service_hash
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

        def lazy_find_pv_claim(ns, name)
          return if ns.nil? || name.nil?

          @collections[:persistent_volume_claims].lazy_find([ns, name])
        end

        def lazy_find_build_pod(name)
          return if name.nil?

          @collections[:build_pods].lazy_find(name)
        end
      end
    end
  end
end
