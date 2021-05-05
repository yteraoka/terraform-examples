terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "=3.60.0"
    }
    #    random = {
    #      version = "=3.1.0"
    #    }
    template = {
      version = "=2.2.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
}

data "google_project" "project" {}
