variable "rg-prefix" {
  type        = string
  description = "RG Prefix"
  default     = "keda-demo"
}

variable "mon_resource_group_name" {
  type        = string
  description = "Azure monitoring Resource Group"
  default     = "mon-core-prod-rg"
}
# ${var.rg-prefix}-svc-core-prod-rg
variable "svc_resource_group_name" {
  type        = string
  description = "Shared Services Resource Group"
  default     = "svc-core-prod-rg"
}

variable "servicebus-name" {
  type    = string
  default = "dapolinasb15"
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "corp_prefix" {
  type        = string
  description = "Corp name Prefix"
  default     = "dapolina0"
}

# LAW module

variable "law_prefix" {
  type    = string
  default = "law"
}


variable "region1_loc" {
  default = "centralus"
}

variable "region2_loc" {
  default = "centralus"
}

variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type        = map(string)

  default = {
    owner = "dapolina"
  }
}

# Azure Bastion module
variable "azurebastion_name_01" {
  type    = string
  default = "corp-bastion-svc_01"
}
variable "azurebastion_addr_prefix" {
  type        = string
  description = "Azure Bastion Address Prefix"
  default     = "10.1.250.0/24"
}

# Azure Firewall
variable "azurefw_name_r1" {
  type    = string
  default = "fwhub1"
}
variable "azurefw_name_r2" {
  type    = string
  default = "fwhub2"
}
variable "azurefw_addr_prefix_r1" {
  type        = string
  description = "Azure Firewall VNET prefix"
  default     = "10.1.254.0/24"
}
variable "azurefw_addr_prefix_r2" {
  type        = string
  description = "Azure Firewall VNET prefix"
  default     = "10.2.254.0/24"
}
# ACR

variable "acr_name" {
  type    = string
  default = "dapolinaacr01"
}

# Jump host1  module
variable "jump_host_name" {
  type    = string
  default = "jumphostvm"
}
variable "jump_host_addr_prefix" {
  type        = string
  description = "Azure Jump Host Address Prefix"
  default     = "10.1.251.0/24"
}
variable "jump_host_private_ip_addr" {
  type        = string
  description = "Azure Jump Host Address"
  default     = "10.1.251.5"
}
variable "jump_host_vm_size" {
  type        = string
  description = "Azure Jump Host VM SKU"
  default     = "Standard_DS3_v2"
}
variable "jump_host_admin_username" {
  type        = string
  description = "Azure Admin Username"
  default     = "azureadmin"
}
variable "jump_host_password" {
  sensitive = true
  type      = string
}
variable "aks_aad_rbac" {}

# jumphost2


variable "jump_host_addr_prefix2" {
  type        = string
  description = "Azure Jump Host Address Prefix"
  default     = "10.2.251.0/24"
}
variable "jump_host_private_ip_addr2" {
  type        = string
  description = "Azure Jump Host Address"
  default     = "10.2.251.5"
}
