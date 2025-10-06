variable "subscription_id" {
  description = "the Azure subscription ID for the Azure Provider"
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
  default     = "UK South"
}

variable "client_ip_cidrs" {
  description = "CIDR for API server access. Defaults to your current public IP /32."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "AKS version (optional). Leave null to let Azure pick a default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for the node pool"
  type        = string
  default     = "standard_d16_v5"
}

variable "enable_local_admin" {
  description = "Enable AKS local admin account to emit admin kubeconfig (convenient for Helm)."
  type        = bool
  default     = true
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
