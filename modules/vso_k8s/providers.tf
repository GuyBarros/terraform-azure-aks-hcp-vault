# Pick admin creds if available, else user creds
locals {
  kube_block = length(data.azurerm_kubernetes_cluster.aks.kube_admin_config) > 0  ? data.azurerm_kubernetes_cluster.aks.kube_admin_config[0]: data.azurerm_kubernetes_cluster.aks.kube_config[0]
}

# Kubernetes provider (bootstrapping SA/CRDs/Helm)
provider "kubernetes" {
  host                   = local.kube_block.host
  client_certificate     = base64decode(local.kube_block.client_certificate)
  client_key             = base64decode(local.kube_block.client_key)
  cluster_ca_certificate = base64decode(local.kube_block.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = local.kube_block.host
    client_certificate     = base64decode(local.kube_block.client_certificate)
    client_key             = base64decode(local.kube_block.client_key)
    cluster_ca_certificate = base64decode(local.kube_block.cluster_ca_certificate)
  }
}

provider "vault" {
  address   = var.vault_addr
  token     = var.vault_token
  namespace = var.vault_namespace
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

