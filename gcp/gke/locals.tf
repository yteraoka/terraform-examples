locals {
  master_authorized_networks_config = length(var.master_authorized_networks) == 0 ? [] : [{
    cidr_blocks = var.master_authorized_networks
  }]
  network_policy_enabled = var.datapath_provider == "ADVANCED_DATAPATH" ? false : var.network_policy_enabled
}
