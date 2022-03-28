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
