resource "azurerm_subnet" "vnet" {
  name                                           = var.subnet_name
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = var.vnet_name
  address_prefixes                               = var.subnet_prefixes
  enforce_private_link_endpoint_network_policies = true

}

data "azurerm_virtual_network" "vnet_name" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_subnet.vnet
  ]

}

