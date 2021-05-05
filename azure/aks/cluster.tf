resource "azurerm_kubernetes_cluster" "main" {
  name                = local.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # required
  # must contain between 3 and 45 characters, and can contain only letters, numbers, and hyphens
  dns_prefix = local.name

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  # 未指定の場合は作成時の最新の推奨バージョンとなる (自動更新はされない)
  kubernetes_version = var.kubernetes_version

  private_cluster_enabled = var.private_cluster_enabled

  role_based_access_control {
    enabled = true
  }

  # 存在しない Resource Group の名前を指定する必要がある
  # Cluster 作成時に Resource Group も作成される
  node_resource_group = "${azurerm_resource_group.main.name}-nodes"

  sku_tier = var.sku_tier

  default_node_pool {
    name                   = "default"
    vm_size                = var.vm_size
    availability_zones     = var.availability_zones
    enable_auto_scaling    = true
    enable_host_encryption = false
    max_pods               = 30
    type                   = "VirtualMachineScaleSets"
    tags = {
      Environment = var.environment_name
      Project     = var.project_name
    }
    upgrade_settings {
      max_surge = "100%"
    }
    max_count  = 3
    min_count  = 1
    node_count = 1
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = file(var.ssh_public_key_path)
    }
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = "loadBalancer"
    load_balancer_sku = "Standard"
    load_balancer_profile {
      managed_outbound_ip_count = 1
    }
  }

  addon_profile {
    # Virtual Kubelet 用
    #aci_connector_linux {
    #  enabled = true
    #  subnet_name = xxx
    #}

    # Gatekeeper 関連
    # https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/rego-for-aks
    #azure_policy {
    #}

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    # https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-onboard
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
      #oms_agent_identity {
      #  client_id = ""
      #  object_id = ""
      #  user_assigned_identity_id = ""
      #}
    }
  }

  auto_scaler_profile {
    # Detect similar node groups and balance the number of nodes between them. Defaults to false.
    #balance_similar_node_groups = false

    # Maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node. Defaults to 600.
    #max_graceful_termination_sec = 600

    # For scenarios like burst/batch scale where you don't want CA to act before
    # the kubernetes scheduler could schedule all the pods, you can tell CA to ignore
    # unscheduled pods before they're a certain age. Defaults to 10s.
    #new_pod_scale_up_delay = "0"

    # How long after the scale up of AKS nodes the scale down evaluation resumes. Defaults to 10m.
    #scale_down_delay_after_add = "10m"

    # How long after node deletion that scale down evaluation resumes. Defaults to the value used for scan_interval.
    #scale_down_delay_after_delete = "10s"

    # How long after scale down failure that scale down evaluation resumes. Defaults to 3m.
    #scale_down_delay_after_failure = "3m"

    # How often the AKS Cluster should be re-evaluated for scale up/down. Defaults to 10s.
    #scan_interval = "10s"

    # How long a node should be unneeded before it is eligible for scale down. Defaults to 10m.
    #scale_down_unneeded = "10m"

    # How long an unready node should be unneeded before it is eligible for scale down. Defaults to 20m.
    #scale_down_unready = "20m"

    # Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down. Defaults to 0.5.
    #scale_down_utilization_threshold = "0.5"

    # If true cluster autoscaler will never delete nodes with pods with local storage, for example, EmptyDir or HostPath. Defaults to true.
    #skip_nodes_with_local_storage = true

    # If true cluster autoscaler will never delete nodes with pods from kube-system (except for DaemonSet or mirror pods). Defaults to true.
    #skip_nodes_with_system_pods = true
  }


  identity {
    type = "SystemAssigned"
    # Custom Private DNS Zone を使う場合は UserAssigned にする必要がある
    #type = "UserAssigned"
    #user_assigned_identity_id = azurerm_user_assigned_identity.main.id
  }

  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }

  #depends_on = [
  #  azurerm_role_assignment.main,
  #]
}
