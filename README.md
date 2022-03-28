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