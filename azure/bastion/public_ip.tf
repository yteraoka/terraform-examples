resource "azurerm_public_ip" "bastion" {
  name                = "${local.name}-bastion"
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
