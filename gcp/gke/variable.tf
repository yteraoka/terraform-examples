variable "project_id" {
  description = "Google Cloud Project Id"
  type        = string
}

variable "base_name" {
  description = "Basename"
  type        = string
}

variable "region" {
  description = "Base Region"
  type        = string
  default     = "asia-northeast1"
}

variable "subnets" {
  description = "Subnets map"
  default = {
    tokyo-01 = {
      region        = "asia-northeast1"
      ip_cidr_range = "10.0.0.0/20"
      secondary_ip_range = {
        services = {
          ip_cidr_range = "172.16.0.0/20"
        }
        pods = {
          ip_cidr_range = "172.17.0.0/16"
        }
      }
      enable_flow_logs = false
      #flow_logs_interval = "INTERVAL_5_SEC"
      #flow_logs_sample   = 0.5
      #flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }
  }
}

variable "cluster_location" {
  description = "cluster の場所 (zone か region を指定)"
  type        = string
  default     = "asia-northeast1-a"
}

variable "master_authorized_networks" {
  description = "API Server へのアクセスを許可する CIDR"
  type = list(
    object({
      cidr_block   = string,
      display_name = string,
    })
  )
  default = []
}

variable "master_ipv4_cidr_block" {
  description = "GKE の Control Plane に割り当てる CIDR"
  type        = string
  default     = "172.31.254.0/28"
}

variable "node_pools" {
  type = map(
    object({
      preemptible             = bool,
      machine_type            = string,
      initial_node_count      = number,
      autoscaling             = object({ min_node_count = number, max_node_count = number }),
      management              = object({ auto_repair = bool, auto_upgrade = bool }),
      upgrade_settings        = object({ max_surge = number, max_unavailable = number }),
      disk_size_gb            = number,
      disk_type               = string,
      ephemeral_storage_count = number,
      image_type              = string
    })
  )
  default = {
    pool1 = {
      preemptible             = true
      machine_type            = "e2-medium"
      initial_node_count      = 1
      disk_size_gb            = 100
      disk_type               = "pd-standard"
      image_type              = "COS_CONTAINERD"
      ephemeral_storage_count = null
      autoscaling = {
        min_node_count = 1
        max_node_count = 3
      }
      management = {
        auto_repair  = true
        auto_upgrade = true
      }
      upgrade_settings = {
        max_surge       = 1
        max_unavailable = 1
      }
    }
  }
}

variable "datapath_provider" {
  type        = string
  description = "DATAPATH_PROVIDER_UNSPECIFIED | LEGACY_DATAPATH | ADVANCED_DATAPATH"
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
  validation {
    condition     = can(regex("^(DATAPATH_PROVIDER_UNSPECIFIED|LEGACY_DATAPATH|ADVANCED_DATAPATH)$", var.datapath_provider))
    error_message = "Unknown provider specified."
  }
}

variable "network_policy_enabled" {
  type        = bool
  description = "network policy を有効にするかどうか"
  default     = true
}

variable "authenticator_groups_config_group" {
  type        = string
  description = "有効にする場合は gke-security-groups@YOUR.DOMAIN を指定する"
  default     = ""
}

variable "network_policy_provider" {
  type        = string
  description = "network policy の provider"
  default     = "CALICO"
}

variable "default_max_pods_per_node" {
  type        = number
  description = "node ごとの pod の最大数であり、node に割り当てる CIDR の大きさとなる"
  default     = 32
}

variable "release_channel" {
  type        = string
  description = "UNSPECIFIED, RAPID, REGULAR, STABLE"
  default     = "REGULAR"
  validation {
    condition     = can(regex("^(UNSPECIFIED|RAPID|REGULAR|STABLE)$", var.release_channel))
    error_message = "Unknown release_channel specified."
  }
}
