resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "main" {
  name = local.name

  # zone を指定すれば zonal, region を指定すれば regional になる
  location = var.gke_location

  networking_mode = "VPC_NATIVE"

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets["asia-northeast1/tokyo-01"].name

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "17:00"
    }
  }

  workload_identity_config {
    identity_namespace = "${data.google_project.project.project_id}.svc.id.goog"
  }

  dynamic "master_authorized_networks_config" {
    for_each = local.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  #  network_policy {
  #  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  for_each = var.nodepools

  name       = each.key
  location   = var.gke_location
  cluster    = google_container_cluster.main.name
  node_count = each.value.node_count

  node_config {
    preemptible  = each.value.preemptible
    machine_type = each.value.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
