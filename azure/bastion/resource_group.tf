resource "azurerm_resource_group" "bastion" {
  name     = local.name
  location = var.location
}
