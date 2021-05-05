variable "location" {
  description = "location name"
  type        = string
  default     = "japaneast"
}

variable "environment_name" {
  description = "environment name"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "vnet_address_space" {
  description = "vnet cidr"
  type        = string
  default     = "10.255.255.0/24"
}

variable "subnet_address_prefixes" {
  description = "bastion 用 subnet cidr"
  type        = string
  default     = "10.255.255.0/27"
}

locals {
  name = join("-", [var.project_name, var.environment_name])
}

