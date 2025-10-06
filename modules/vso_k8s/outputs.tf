output "vault_k8s_auth_path" {
  value = vault_auth_backend.kubernetes.path
}

output "workload_role" {
  value = vault_kubernetes_auth_backend_role.workload_role.role_name
}
