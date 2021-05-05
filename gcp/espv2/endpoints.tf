data "template_file" "openapi_spec" {
  template = file("openapi_spec.yaml")
  vars = {
    endpoints_hostname = local.endpoints_hostname
  }
}

resource "google_endpoints_service" "openapi_service" {
  service_name   = local.endpoints_hostname
  project        = data.google_project.project.project_id
  openapi_config = data.template_file.openapi_spec.rendered
}
