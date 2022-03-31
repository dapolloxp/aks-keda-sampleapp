data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storageaccountname
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind = "FileStorage"
  enable_https_traffic_only = false
  network_rules {
      bypass         = ["AzureServices"]
      default_action = "Deny"
      ip_rules = [
      "${chomp(data.http.myip.body)}"
    ]
  }
}

resource "azurerm_storage_share" "fileshare" {
  name                 = "nfsshare"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 102400
  enabled_protocol = "NFS"
}
/*
resource "azurerm_storage_share_directory" "nfsdir" {
  name                 = "nfsdirectory"
  share_name           = azurerm_storage_share.fileshare.name
  storage_account_name = azurerm_storage_account.storage_account.name
}*/

resource "azurerm_private_endpoint" "sa_pe" {
  name                = "storage-endpoint"
  location            = azurerm_storage_account.storage_account.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.shared_subnetid

  private_service_connection {
    name                           = "storageaccount-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["file"]

    
  }
  private_dns_zone_group {
    name                 = var.azfiles_private_zone_name
    private_dns_zone_ids = [var.azfiles_private_zone_id]
  }
}

