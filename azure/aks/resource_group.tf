resource "azurerm_resource_group" "main" {
  name     = local.name
  location = var.location
  tags = {
    Environment = var.environment_name
    Project     = var.project_name
  }
}
