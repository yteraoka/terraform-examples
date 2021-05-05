locals {
  name = "${var.project_name}-${var.environment_name}"
  master_authorized_networks_config = length(var.master_authorized_networks) == 0 ? [] : [{
    cidr_blocks : var.master_authorized_networks
  }]
  endpoints_hostname = "${var.endpoints_service_name}.endpoints.${data.google_project.project.project_id}.cloud.goog"
}
