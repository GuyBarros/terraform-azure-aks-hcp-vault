# Use this when enable_local_admin = true
output "kubeconfig" {
  description = "Kubeconfig for admin access (use with care)."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "api_server_allowed_cidrs" {
  value = azurerm_kubernetes_cluster.aks.api_server_access_profile[0].authorized_ip_ranges
}
