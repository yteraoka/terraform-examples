resource "azurerm_virtual_network" "bastion" {
  name                = local.name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.bastion.name
  virtual_network_name = azurerm_virtual_network.bastion.name
  address_prefixes     = [var.subnet_address_prefixes]
}
