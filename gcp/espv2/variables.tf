variable "project_name" {
  description = "project name"
  type        = string
}

variable "environment_name" {
  description = "environment name"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gke_location" {
  description = "GKE location"
  type        = string
  default     = "asia-northeast1-a"
}

variable "nodepools" {
  description = "Node Pool config list"
  type        = map(map(string))
}

variable "master_authorized_networks" {
  description = "Allow access to API server"
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = []
}

variable "endpoints_service_name" {
  default = "echo-api3"
}
