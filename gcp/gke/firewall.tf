resource "google_compute_firewall" "asm_webhook" {
  name    = "${var.base_name}-asm-webhook"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["15017"]
  }
  source_ranges = [google_container_cluster.blue.private_cluster_config[0].master_ipv4_cidr_block]
}
