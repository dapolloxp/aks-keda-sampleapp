terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.8.0"
    }
  }
}
provider "azurerm" {
  features {
     resource_group {
       prevent_deletion_if_contains_resources = false
     }
   }
}

resource "random_string" "random" {
  length = 13
  upper = false
  special = false

}

# Resource group 
resource "azurerm_resource_group" "mon_rg" {
  name     = "${var.rg-prefix}-mon-core-prod-${var.region1_loc}-rg"
  location = var.region1_loc
  tags = {
    "Workload"      = "Core Infra"
    "Data Class"    = "General"
    "Business Crit" = "Low"
  }
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.rg-prefix}-aks-core-prod-${var.region1_loc}-rg"
  location = var.region1_loc
  tags = {
    "Workload"      = "Core Infra"
    "Data Class"    = "General"
    "Business Crit" = "Low"
  }
}

resource "azurerm_resource_group" "svc_rg" {
  name     = "${var.rg-prefix}-svc-core-prod-rg"
  location = var.region1_loc
  tags = {
    "Workload"      = "Core Infra"
    "Data Class"    = "General"
    "Business Crit" = "High"
  }
}

module "log_analytics" {
  source              = "../../modules/log_analytics"
  resource_group_name = azurerm_resource_group.mon_rg.name
  location            = var.region1_loc
  law_name            = "${var.law_prefix}-core-${azurerm_resource_group.mon_rg.location}-${random_string.random.result}"
}

resource "azurerm_resource_group" "hub_region1" {
  name     = "${var.rg-prefix}-net-core-hub-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

module "hub_region1" {
  source              = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.hub_region1.name
  location            = azurerm_resource_group.hub_region1.location

  vnet_name     = "vnet-hub-${var.region1_loc}"
  address_space = "10.1.0.0/16"
  dns_servers = ["168.63.129.16"]
}

module "azure_storage" {
  source = "../../modules/storage"
  resource_group_name = azurerm_resource_group.hub_region1.name
  location            = azurerm_resource_group.hub_region1.location
  storageaccountname  = "${var.rg-prefix}${random_string.random.result}"
  shared_subnetid =   module.id_spk_region1_default_subnet.subnet_id
  azblob_private_zone_id   = module.private_dns.azblob_private_zone_id
  azblob_private_zone_name = module.private_dns.azblob_private_zone_name
}

module "hub_region1_default_subnet" {
  source              = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.hub_region1.name
  vnet_name           = module.hub_region1.vnet_name
  subnet_name         = "default-subnet"
  subnet_prefixes     = ["10.1.1.0/24"]
  azure_fw_ip         = module.azure_firewall_region1.ip
}

resource "azurerm_ip_group" "ip_g_region1_hub" {
  name                = "region1-hub-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs               = ["10.1.0.0/16"]

}

resource "azurerm_ip_group" "ip_g_region1_aks_spoke" {
  name                = "region1-aks-spoke-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs               = ["10.3.0.0/16"]
}

resource "azurerm_ip_group" "ip_g_region1_pe_spoke" {
  name                = "region1-pe-spoke-ipgroup"
  location            = azurerm_resource_group.hub_region1.location
  resource_group_name = azurerm_resource_group.hub_region1.name
  cidrs               = ["10.4.0.0/16"]
}

resource "azurerm_resource_group" "id_spk_region1" {
  name     = "${var.rg-prefix}-net-aks-spk-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

# Create AKS spoke for region1
module "id_spk_region1" {
  source              = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  location            = azurerm_resource_group.id_spk_region1.location
  vnet_name           = "vnet-aks-spk-${var.region1_loc}"
  //address_space       = "10.3.0.0/16"
  address_space =  "10.3.0.0/16"
  # default_subnet_prefixes = ["10.3.1.0/24"]
  dns_servers = [module.azure_firewall_region1.ip]
}
# temp spoke
module "id_pe_region1" {
  source              = "../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  location            = azurerm_resource_group.id_spk_region1.location
  vnet_name           = "vnet-pe-spk-${var.region1_loc}"
  address_space       = "10.4.0.0/16"

  dns_servers = [module.azure_firewall_region1.ip]
}

module "id_pe_region1_default_subnet" {
  source              = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  vnet_name           = module.id_pe_region1.vnet_name
  subnet_name         = "pe-subnet"
  //subnet_prefixes = ["10.3.1.0/24"]
  subnet_prefixes = ["10.4.1.0/24"]
  azure_fw_ip     = module.azure_firewall_region1.ip
}

# Peering between hub1 and pe spoke
module "peering_pe_spk_Region1_1" {
  source               = "../../modules/networking/peering_direction1"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_pe_region1.vnet_name
  netB_id              = module.id_pe_region1.vnet_id
}

# Peering between pe spoke and hub
module "peering_spk_pe_Region1_1" { 
  source               = "../../modules/networking/peering_direction2"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_pe_region1.vnet_name
  netB_id              = module.id_pe_region1.vnet_id

  depends_on = [module.peering_pe_spk_Region1_1]
}


#################################

module "id_spk_region1_default_subnet" {
  source              = "../../modules/networking/subnet"
  resource_group_name = azurerm_resource_group.id_spk_region1.name
  vnet_name           = module.id_spk_region1.vnet_name
  subnet_name         = "aks-subnet"
  //subnet_prefixes = ["10.3.1.0/24"]
  //subnet_prefixes = ["10.3.4.0/16"]
  subnet_prefixes = ["10.3.0.0/16"]
  azure_fw_ip     = module.azure_firewall_region1.ip
}

# Peering between hub1 and spk1
module "peering_aks_spk_Region1_1" {
  source               = "../../modules/networking/peering_direction1"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_spk_region1.vnet_name
  netB_id              = module.id_spk_region1.vnet_id
}

# Peering between hub1 and spk1
module "peering_id_spk_Region1_2" {
  source               = "../../modules/networking/peering_direction2"
  resource_group_nameA = azurerm_resource_group.hub_region1.name
  resource_group_nameB = azurerm_resource_group.id_spk_region1.name
  netA_name            = module.hub_region1.vnet_name
  netA_id              = module.hub_region1.vnet_id
  netB_name            = module.id_spk_region1.vnet_name
  netB_id              = module.id_spk_region1.vnet_id

  depends_on = [module.peering_aks_spk_Region1_1]
}

module "aks" {
  source                   = "../../modules/aks"
  resource_group_name      = azurerm_resource_group.aks_rg.name
  location                 = var.region1_loc
  aks_spoke_subnet_id      = module.id_spk_region1_default_subnet.subnet_id
  hub_virtual_network_id   = module.hub_region1.vnet_id
  spoke_virtual_network_id = module.id_spk_region1.vnet_id
  depends_on = [
    module.id_spk_region1_default_subnet,
    module.jump_host,
    module.log_analytics
  ]
  acr_id       = module.acr.acr_id
  key_vault_id = module.hub_keyvault.kv_key_zone_id
  azure_active_directory_role_based_access_control = var.aks_aad_rbac
}

module "acr" {
  source              = "../../modules/acr"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = var.region1_loc
  subnet_id           = module.id_spk_region1_default_subnet.subnet_id
  acr_name            = var.acr_name
  acr_private_zone_id = module.private_dns.acr_private_zone_id

}

module "private_dns" {
  source                 = "../../modules/azure_dns"
  resource_group_name    = azurerm_resource_group.svc_rg.name
  location               = var.region1_loc
  hub_virtual_network_id = module.hub_region1.vnet_id
}

module "service_bus" {
  source              = "../../modules/service_bus"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = var.region1_loc
  sb-name             = var.servicebus-name
  sb_private_zone_id  = module.private_dns.sb_private_zone_id
  subnet_id           = module.id_spk_region1_default_subnet.subnet_id
}

module "keda_app" {
  source              = "../../modules/keda"
  resource_group_name = module.aks.node_resource_group
  location            = var.region1_loc
  sb_id               = module.service_bus.service_bus_id
}

resource "azurerm_route_table" "default_aks_route" {
  name                = "default_aks_route"
  resource_group_name = azurerm_resource_group.hub_region1.name
  location            = var.region1_loc
  route {
    name                   = "default_egress"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_firewall_region1.ip
  }
  depends_on = [
    module.azure_firewall_region1
  ]
}

# Bastion Host
module "bastion_region1" {
  source                   = "../../modules/azure_bastion"
  resource_group_name      = azurerm_resource_group.hub_region1.name
  location                 = azurerm_resource_group.hub_region1.location
  azurebastion_name        = var.azurebastion_name_01
  azurebastion_vnet_name   = module.hub_region1.vnet_name
  azurebastion_addr_prefix = "10.1.250.0/24"
}

module "azure_firewall_region1" {
  source                  = "../../modules/azure_firewall"
  resource_group_name     = azurerm_resource_group.hub_region1.name
  location                = azurerm_resource_group.hub_region1.location
  azurefw_name            = "azfw-${random_string.random.result}"
  azurefw_vnet_name       = module.hub_region1.vnet_name
  azurefw_addr_prefix     = var.azurefw_addr_prefix_r1
  sc_law_id               = module.log_analytics.log_analytics_id
  region1_aks_spk_ip_g_id = azurerm_ip_group.ip_g_region1_aks_spoke.id
  depends_on = [ module.log_analytics]
}

# Jump host  Errors on creation with VMExtention is commented out

module "jump_host" { 
  source                    = "../../modules/jump_host"
  resource_group_name       = azurerm_resource_group.hub_region1.name
  location                  = azurerm_resource_group.hub_region1.location
  jump_host_name            = var.jump_host_name
  jump_host_vnet_name       = module.hub_region1.vnet_name
  jump_host_addr_prefix     = var.jump_host_addr_prefix
  jump_host_private_ip_addr = var.jump_host_private_ip_addr
  jump_host_vm_size         = var.jump_host_vm_size
  jump_host_admin_username  = var.jump_host_admin_username
  jump_host_password        = var.jump_host_password
  key_vault_id              = module.hub_keyvault.kv_key_zone_id
  kv_rg                     = azurerm_resource_group.id_shared_region1.name
  depends_on = [
    azurerm_resource_group.id_shared_region1,
    module.bastion_region1
    
  ]
}

resource "azurerm_resource_group" "id_shared_region1" { 
  name     = "${var.rg-prefix}-shared-svc-spk-${var.region1_loc}-rg"
  location = var.region1_loc
  tags     = var.tags
}

#Need to fix Private Endpoint and location of DNS Zone

module "hub_keyvault" {
  source              = "../../modules/key_vault"
  resource_group_name = azurerm_resource_group.id_shared_region1.name
  location            = azurerm_resource_group.id_shared_region1.location
  keyvault_name       = "kv-${var.corp_prefix}-${var.region1_loc}"
  shared_subnetid       = module.id_spk_region1_default_subnet.subnet_id
  kv_private_zone_id   = module.private_dns.kv_private_zone_id
  kv_private_zone_name = module.private_dns.kv_private_zone_name
  depends_on             = [module.id_spk_region1_default_subnet]
}