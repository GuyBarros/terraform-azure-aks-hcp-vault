
#############################
# 1) Reviewer SA + RBAC
#############################
resource "kubernetes_namespace" "vault_auth" {
  metadata { name = "vault-auth" }
}
resource "kubernetes_namespace" "vso" {
  metadata { name = var.vso_namespace }
}

resource "kubernetes_service_account" "reviewer" {
  metadata {
    name      = "vault-auth-reviewer"
    namespace = kubernetes_namespace.vault_auth.metadata[0].name
  }
}

resource "kubernetes_secret" "reviewer_token" {
  metadata {
    name        = "vault-auth-reviewer-token"
    namespace   = kubernetes_namespace.vault_auth.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.reviewer.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role" "tokenreview" {
  metadata { name = "vault-tokenreview" }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "secrets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "tokenreview_bind" {
  metadata { name = "vault-tokenreview-bind" }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.tokenreview.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.reviewer.metadata[0].name
    namespace = kubernetes_namespace.vault_auth.metadata[0].name
  }
}

#############################
# 2) Vault Kubernetes auth
#############################
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.vault_k8s_auth_path
}

resource "vault_kubernetes_auth_backend_config" "cfg" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  kubernetes_ca_cert = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  token_reviewer_jwt = kubernetes_secret.reviewer_token.data["token"]
  # issuer = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url  # enable if you use OIDC issuer validation
}

# Demo policy for your apps (read-only on kv v2 mount "kv", path "app/*")
resource "vault_policy" "k8s_demo" {
  name   = "k8s-demo"
  policy = <<-EOT
    path "*" {
      capabilities = ["read","list","update","create","delete"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "workload_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "app-role"
  bound_service_account_names      = var.workload_service_accounts
  bound_service_account_namespaces = [var.workload_namespace]
  token_policies                   = [vault_policy.k8s_demo.name]
  token_ttl                        = 3600
  token_max_ttl                    = 7200
}

#############################
# 3) Vault Secrets Operator
#############################


resource "vault_policy" "vso_sync" {
  name   = "vso-sync"
  policy = <<-EOT
    path "kv/data/app/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "vso_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vso"
  bound_service_account_names      = ["vault-secrets-operator"]
  bound_service_account_namespaces = [var.vso_namespace]
  token_policies                   = [vault_policy.vso_sync.name]
  token_ttl                        = 3600
  token_max_ttl                    = 7200
}

resource "helm_release" "vso" {
  name       = "vault-secrets-operator"
  namespace  = var.vso_namespace
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"
  version    = var.vso_chart_version

  values = [yamlencode({
    defaultVaultConnection = {
      enabled = true
      name    = "default"
      address = var.vault_addr
      # caCertSecretRef = "vault-ca"    # if you need to trust a custom CA
      # skipTLSVerify   = false
    }
    defaultAuthMethod = {
      enabled = true
      name    = "kubernetes-auth"
      type    = "kubernetes"
      mount   = var.vault_k8s_auth_path
      kubernetes = {
        role           = vault_kubernetes_auth_backend_role.vso_role.role_name
        serviceAccount = "default"
      }
      namespace         = var.vault_namespace
      vaultConnectionRef = "default"
    }
  })]

  depends_on = [vault_kubernetes_auth_backend_role.vso_role]
}
