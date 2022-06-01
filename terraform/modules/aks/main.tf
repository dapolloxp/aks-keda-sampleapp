/*
resource "azurerm_private_dns_zone" "aks_dns_zone" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
}*/

resource "azurerm_user_assigned_identity" "aks_master_identity" {
  name                = "aks-master-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}
/*
resource "azurerm_role_assignment" "aks_master_role_assignment" {
  scope                = azurerm_private_dns_zone.aks_dns_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_master_identity.principal_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub_link" {
  name                  = "aks-cloud-hub-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = var.hub_virtual_network_id
}*/
/*
resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke_link" {
  name                  = "aks-spoke-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = var.spoke_virtual_network_id
}*/

data "azurerm_key_vault_secret" "kv_secret" {
  name         = "akssshkey"
  key_vault_id = var.key_vault_id
}

resource "azurerm_kubernetes_cluster" "aks_c" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_dns_prefix
  sku_tier = "Paid"
  kubernetes_version = var.kubernetes_version
  identity {
    type                      = "UserAssigned"
  //  user_assigned_identity_id = azurerm_user_assigned_identity.aks_master_identity.id
    identity_ids              = [azurerm_user_assigned_identity.aks_master_identity.id]
  }
  azure_policy_enabled = true

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = data.azurerm_key_vault_secret.kv_secret.value
    }

  }

  auto_scaler_profile {
    expander              = "most-pods"
    scan_interval         = "60s"
    empty_bulk_delete_max = "100"
    scale_down_delay_after_add = "4m"
    scale_down_unready  = "4m"
  }

  role_based_access_control_enabled = true
  
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_active_directory_role_based_access_control.enabled ? [1] : []
    content {
      managed = var.azure_active_directory_role_based_access_control.enabled     
      admin_group_object_ids = var.azure_active_directory_role_based_access_control.admin_group_object_ids
      azure_rbac_enabled = var.azure_active_directory_role_based_access_control.enabled
    }
  }
  
//  private_cluster_enabled = true
//  private_dns_zone_id     = azurerm_private_dns_zone.aks_dns_zone.id

  network_profile {
    network_plugin     = "azure"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    load_balancer_sku  = "standard"
   // outbound_type      = "userDefinedRouting"
    outbound_type =  "userAssignedNATGateway"
    nat_gateway_profile {
      managed_outbound_ip_count = 16
    }
  }

  default_node_pool {
    name                = "defaultpool"
    vm_size             = var.machine_type
    node_count          = var.default_node_pool_size
    vnet_subnet_id      = var.aks_spoke_subnet_id
   // os_disk_type = "Managed"
   // os_sku = "Premium"
  //  os_disk_size_gb = "1024"
    enable_auto_scaling = true
    max_count           = 10
    min_count           = 1
    kubelet_disk_type   = "Temporary"
    os_disk_type = "Ephemeral"
  }
  /*
  depends_on = [
    azurerm_role_assignment.aks_master_role_assignment,
  ]*/
  depends_on = [
    azurerm_nat_gateway.natgw
  ]
}

data "azurerm_subscription" "current_sub" {
}

resource "azurerm_role_assignment" "rbac_assignment" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}
/*
resource "null_resource" "keda_install" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts && helm repo update && helm install aad-pod-identity aad-pod-identity/aad-pod-identity;"
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "helm repo add kedacore https://kedacore.github.io/charts && helm repo update && kubectl create namespace keda && helm install keda kedacore/keda --set podIdentity.activeDirectory.identity=app-autoscaler --namespace keda;"
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "kubectl create namespace keda-dotnet-sample;"
  EOF
  }
}*/

resource "azurerm_role_assignment" "rbac_assignment_sub_network_c" {
  scope                = data.azurerm_subscription.current_sub.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "rbac_assignment_sub_managed_mi_c" {
  scope                = data.azurerm_subscription.current_sub.id
  role_definition_name = "Managed Identity Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "rbac_assignment_sub_managed_mi_o" {
  scope                = data.azurerm_subscription.current_sub.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}


resource "azurerm_role_assignment" "rbac_assignment_sub_managed_mi_reader" {
  scope                = data.azurerm_subscription.current_sub.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "rbac_assignment_sub_managed_vm_c" {
  scope                = data.azurerm_subscription.current_sub.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}

data "azurerm_client_config" "current" {}


resource "azurerm_role_assignment" "aks_rbac_cluster_admin_current_user" {
  scope = data.azurerm_subscription.current_sub.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
 // principal_id         = data.azurerm_client_config.current.object_id
 principal_id = "ba020750-47a8-496b-8206-551e1d062ffb"
}


## NAT GW specifics

resource "azurerm_public_ip_prefix" "pipprefix" {
  name                = "nat-gateway-publicIPPrefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = 29
  
}


resource "azurerm_subnet_nat_gateway_association" "natgwsubassoc" {
  subnet_id      = var.aks_spoke_subnet_id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "example" {
  nat_gateway_id      = azurerm_nat_gateway.natgw.id
  public_ip_prefix_id = azurerm_public_ip_prefix.pipprefix.id
}

resource "azurerm_nat_gateway" "natgw" {
  name                    = "NAT-Gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  #public_ip_address_ids   = [azurerm_public_ip.example.id]
 # public_ip_prefix_ids    = [azurerm_public_ip_prefix.pipprefix.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

resource "azurerm_public_ip" "pip" {
  name                = "example-PIP"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "pipassoc" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.pip.id
}