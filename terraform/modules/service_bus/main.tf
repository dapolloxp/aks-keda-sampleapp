resource "azurerm_servicebus_namespace" "sb_premium" {
  name                = var.sb-name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  capacity            = 1
}

resource "azurerm_servicebus_queue" "orders_queue" {
  name                = "orders"
  #resource_group_name = var.resource_group_name
  #namespace_name      = azurerm_servicebus_namespace.sb_premium.name
  namespace_id = azurerm_servicebus_namespace.sb_premium.id
  enable_partitioning = true
}
/*
resource "azurerm_private_endpoint" "sb_pe" {
  name                = "sb-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  private_service_connection {
    name                           = "sb-private-link-connection"
    private_connection_resource_id = azurerm_servicebus_namespace.sb_premium.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = element(split("/", var.sb_private_zone_id), length(split("/", var.sb_private_zone_id)) - 1)
    private_dns_zone_ids = [var.sb_private_zone_id]
  }
}
*/