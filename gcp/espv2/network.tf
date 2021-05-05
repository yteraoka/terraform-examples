module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = data.google_project.project.project_id
  network_name = "${var.project_name}-${var.environment_name}-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "tokyo-01"
      subnet_ip             = "10.0.0.0/16"
      subnet_region         = "asia-northeast1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "tokyo-01"
    }
  ]

  secondary_ranges = {
    tokyo-01 = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "10.2.0.0/16"
      }
    ]
  }
}
