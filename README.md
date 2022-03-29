# aks-keda-sampleapp

## Secured Private AKS with a sample keda app

This repo deploys a hub and spoke architecture with a private AKS cluster. Other components that are deployed as part of this terraform deployment are the following:

* Azure Firewall Manager with a base policy and IP groups
* Azure Container Registry with Private Endpoint (PE)
* Private Cluster with Outbound Type UDR
* VNET with a spoke for AKS and ACR
* Bastion Service with NSG
* Key Vault with Private Endpoint
* Azure Monitor

## How to deploy?

To run this script, change to the following directory

terraform/landing_zone/single_region

There are two files location here:

* main.tf
* variables.tf

You will be prompted for the following variables:

* jump_host_password 
* aks_aad_rbac 

If desired, you can create a file with the extension of tfvars, such as mysettings.tfvar, in the following structure:

jump_host_password = "Your Secure Password"

aks_aad_rbac = {
    enabled = true
    admin_group_object_ids = ["Object ID of your group/user"]
}

terraform apply -f main.tf --var-file=mysettings.tfvars

Once completed the following resource groups are created:

* {prefix}-aks-core-prod-eastus2-rg
  This holds the AKS managed Identity, AKS Service, the AKS private DNS zone, and Service Bus.

* {prefix}-mon-core-prod-eastus2-rg
  Contains the log analytics workspace.

* {prefix}-net-aks-spk-eastus2-rg
  Contains the spoke VNETs and route tables.
  
* {prefix}-net-core-hub-eastus2-rg
  This holds Azure Firewall, Azure Firewall policies, Bastion service, NSGs, Jumphost, Hub VNET, and associated IP groups.

* {prefix}-shared-svc-spk-eastus2-rg
  Contains key vault and the associated private endpoint
  
* {prefix}-svc-core-prod-rg
  contains the ACR DNS zone, service bus DNS zone, and Key vault zone.

* AKS MC resource group (automatically created )
  This is the default resource group created by AKS for Managed Identities, Node Pools, etc.