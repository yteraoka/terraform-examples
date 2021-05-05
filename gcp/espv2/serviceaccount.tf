resource "google_service_account" "esp_demo" {
  account_id   = "esp-demo-${local.name}"
  display_name = "Container Account for ESPv2 Demo"
}

resource "google_project_iam_member" "esp_demo_service_controller" {
  project = data.google_project.project.project_id
  role    = "roles/servicemanagement.serviceController"
  member  = "serviceAccount:${google_service_account.esp_demo.email}"
}

resource "google_project_iam_member" "esp_demo_cloud_trace" {
  project = data.google_project.project.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.esp_demo.email}"
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.esp_demo.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[default/esp-echo]"
  ]
}

output "esp_sa" {
  value = google_service_account.esp_demo
}
