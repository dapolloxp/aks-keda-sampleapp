output "acr_private_zone_id" {
  value = azurerm_private_dns_zone.acr_zone.id
}

output "kv_private_zone_id" {
  value = azurerm_private_dns_zone.keyvault_zone.id
}

output "kv_private_zone_name" {
  value = azurerm_private_dns_zone.keyvault_zone.name
}

output "sb_private_zone_id" {
  value = azurerm_private_dns_zone.servicebus_zone.id
}

output "azfiles_private_zone_id" {
  value = azurerm_private_dns_zone.azurefiles_zone.id
}

output "azfiles_private_zone_name" {
  value = azurerm_private_dns_zone.azurefiles_zone.name
}