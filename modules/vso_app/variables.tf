variable "resource_group_name" {
  type = string
}

variable "aks_cluster_name" {
  type = string
}

variable "vault_addr" {
  type = string
}

variable "vault_token" {
  type      = string
  sensitive = true
}

variable "vault_namespace" {
  type    = string
  default = "root"
}

variable "vault_k8s_auth_path" {
  type    = string
  default = "kubernetes"
}

variable "workload_namespace" {
  type    = string
  default = "default"
}

variable "workload_service_accounts" {
  type    = list(string)
  default = ["default"]
}

variable "vso_namespace" {
  type    = string
  default = "vault-secrets-operator"
}

variable "vso_chart_version" {
  type    = string
  default = "0.10.0"
}

variable "subscription_id" {
  description = "the Azure subscription ID for the Azure Provider"
}
