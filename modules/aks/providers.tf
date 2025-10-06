provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "vault" {
  
}


provider "kubernetes" {
   config_path    = "../../kubeconfig_admin"
#  token    = var.cluster_token
#  host     = var.cluster_api_url
#  insecure = var.cluster_insecure_skip_tls_verify
}
