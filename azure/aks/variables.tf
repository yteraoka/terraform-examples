variable "location" {
  description = "location name"
  type        = string
  default     = "japaneast"
}

variable "resource_group_name_prefix" {
  description = "resource group name prefix"
  type        = string
  default     = ""
}

variable "environment_name" {
  description = "environment name"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "vm_size" {
  description = "node pool の vm size"
  type        = string
  default     = "Standard_B2ms"
}

variable "availability_zones" {
  description = "node pool の配置先 zone リスト"
  type        = list(number)
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  description = "API サーバーにアクセス可能な CIDR リスト"
  type        = list(string)
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes の Version"
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Private Cluster にするかどうか"
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "Free or Paid"
  type        = string
  default     = "Free"
}

variable "log_analytics_sku" {
  description = "PerGB2018 一択"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "log_analytics の保存日数 (30-730)"
  type        = number
  default     = 30
}

variable "log_analytics_daily_quota_gb" {
  description = "1日あたりの投入限度GB (-1 は無制限)"
  type        = number
  default     = 1
}

variable "ssh_public_key_path" {
  description = "Node VM にアクセスするための SSH の Public Key の path"
  type        = string
}

locals {
  name = join("-", [var.project_name, var.environment_name])
}

