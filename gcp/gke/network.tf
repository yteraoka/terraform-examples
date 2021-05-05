resource "google_compute_network" "vpc" {
  name                            = "${var.base_name}-vpc"
  description                     = "${var.base_name} VPC"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  provider                 = google-beta
  network                  = google_compute_network.vpc.name
  name                     = join("-", [var.base_name, each.key])
  ip_cidr_range            = each.value["ip_cidr_range"]
  region                   = each.value["region"]
  private_ip_google_access = true

  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_range")
    content {
      range_name    = join("-", [var.base_name, each.key, secondary_ip_range.key])
      ip_cidr_range = secondary_ip_range.value["ip_cidr_range"]
    }
  }

  dynamic "log_config" {
    for_each = lookup(each.value, "enable_flow_logs", true) ? [
      {
        aggregation_interval = lookup(each.value, "flow_logs_interval", "INTERVAL_5_SEC")
        flow_sampling        = lookup(each.value, "flor_logs_sample", 0.5)
        metadata             = lookup(each.value, "flow_logs_metadata", "INCLUDE_ALL_METADATA")
      }
    ] : []
    content {
      aggregation_interval = log_config.value["aggregation_interval"]
      flow_sampling        = log_config.value["flow_sampling"]
      metadata             = log_config.value["metadata"]
    }
  }
}

resource "google_compute_router" "router" {
  name    = "${var.base_name}-default"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.base_name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
