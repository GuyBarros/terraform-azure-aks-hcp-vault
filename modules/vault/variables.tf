variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
  default     = "UK South"
}

variable "subscription_id" {
  description = "the Azure subscription ID for the Azure Provider"
}
variable "azure_resource_group_name" {
  description = "Name of the existing Resource Group to deploy AKS into"
  type        = string
}
variable "aks_cluster_name" {
  description = "Name of the AKS cluster to integrate with"
  type        = string
}
variable "vault_addr" {
  description = "Vault URL, e.g. https://vault.example.com:8200"
  type        = string
}

variable "vault_token" {
  description = "Vault root or bootstrap token with auth enable/capabilities"
  type        = string
  sensitive   = true
}

variable "vault_namespace" {
  description = "Vault Enterprise namespace (leave as 'root' for OSS)"
  type        = string
  default     = "root"
}

variable "vault_k8s_auth_path" {
  description = "Path to mount the Kubernetes auth method"
  type        = string
  default     = "kubernetes"
}

variable "workload_namespace" {
  description = "Kubernetes namespace whose pods will authenticate to Vault"
  type        = string
  default     = "default"
}

variable "workload_service_accounts" {
  description = "Service accounts in workload_namespace that may authenticate"
  type        = list(string)
  default     = ["default"]
}
