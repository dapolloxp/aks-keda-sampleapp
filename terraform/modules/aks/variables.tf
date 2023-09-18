variable "location" {}
variable "resource_group_name" {}
variable "aks_spoke_subnet_id" {}
variable "spoke_virtual_network_id" {}
variable "hub_virtual_network_id" {}
variable "machine_type" {
  description = "The Azure Machine Type for the AKS Node Pool"
  default     = "standard_d4s_v3"
}
variable "service_cidr" {
  description = "Service CIDR"
  default     = "10.211.0.0/16"
}

variable "acr_id" {

}

variable "key_vault_id" {}
variable "dns_service_ip" {
  description = "dns_service_ip"
  default     = "10.211.0.10"
}
variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  default     = "172.17.0.1/16"
}

variable "default_node_pool_size" {
  description = "The default number of VMs for the AKS Node Pool"
  default     = 1
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use for the cluster."
  default     = "1.27.3"
}

variable "aks_cluster_name" {
  description = "AKS Cluster name"
  default     = "test-cluster"
}
variable "aks_dns_prefix" {
  description = "AKS Prefix Name"
  default     = "dapolina"
}

variable "azure_active_directory_role_based_access_control" {
    type        = object({
        enabled                = bool 
        admin_group_object_ids = tuple([string])
    })
    default     = {
        enabled                = false 
        admin_group_object_ids = null 
    }
}

variable "disk_encryption_set_id" {
    type        = string
    description = "Disk Encryption Set ID"
}