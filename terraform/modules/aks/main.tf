
resource "azurerm_private_dns_zone" "aks_dns_zone" {
  name                = "privatelink.eastus2.azmk8s.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "aks_master_identity" {
  name                = "aks-master-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

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
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke_link" {
  name                  = "aks-spoke-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = var.spoke_virtual_network_id
}

data "azurerm_key_vault_secret" "kv_secret" {
  name         = "test"
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
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_master_identity.id
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
  
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks_dns_zone.id

  network_profile {
    network_plugin     = "azure"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
  }

  default_node_pool {
    name                = "defaultpool"
    vm_size             = var.machine_type
    node_count          = var.default_node_pool_size
    vnet_subnet_id      = var.aks_spoke_subnet_id
    enable_auto_scaling = true
    max_count           = 10
    min_count           = 1
  }
  depends_on = [
    azurerm_role_assignment.aks_master_role_assignment,
  ]
}

data "azurerm_subscription" "current_sub" {
}

resource "azurerm_role_assignment" "rbac_assignment" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_c.kubelet_identity[0].object_id
}

resource "null_resource" "keda_install" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts && helm repo update && helm install aad-pod-identity aad-pod-identity/aad-pod-identity;"
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "helm repo add kedacore https://kedacore.github.io/charts && helm repo update && kubectl create namespace keda && helm install keda kedacore/keda --set podIdentity.activeDirectory.identity=app-autoscaler --namespace keda;"
    az aks command invoke -g ${var.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_c.name} -c "kubectl create namespace keda-dotnet-sample;"
  EOF
  }
}

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
