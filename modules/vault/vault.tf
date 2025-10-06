

############################################################
# 1) Create a TokenReview-capable ServiceAccount on AKS
############################################################

# Namespace to hold the reviewer SA (separate from your workloads)
resource "kubernetes_namespace" "vault_auth" {
  metadata {
    name = "vault-auth"
  }
}

resource "kubernetes_service_account" "reviewer" {
  metadata {
    name      = "vault-auth-reviewer"
    namespace = kubernetes_namespace.vault_auth.metadata[0].name
  }
}

# Kubernetes v1.24+ doesn't auto-create SA tokens.
# This special Secret requests a long-lived token for the SA.
resource "kubernetes_secret" "reviewer_token" {
  metadata {
    name      = "vault-auth-reviewer-token"
    namespace = kubernetes_namespace.vault_auth.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.reviewer.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# (Optional) RBAC to let the reviewer call TokenReview. AKS allows this by default
# to kube-apiserver internals, but we include a minimal, explicit bind:
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

############################################################
# 2) Enable & configure Vault Kubernetes auth method
############################################################

# Enable (or reference) the auth mount
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.vault_k8s_auth_path
}

# Configure it with AKS API endpoint, CA, and the reviewer JWT
resource "vault_kubernetes_auth_backend_config" "this" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = azurerm_kubernetes_cluster.aks.kube_config[0].host
  kubernetes_ca_cert     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  token_reviewer_jwt     = kubernetes_secret.reviewer_token.data["token"]

  # issuer is optional; AKS projected SA tokens typically validate via TokenReview.
  # You can uncomment if you've enabled AKS OIDC issuer and want strict validation:
  # issuer = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

############################################################
# 3) Example: a simple policy + role for your workloads
############################################################

# Minimal demo policy: allow reading a kv v2 path "kv/data/app/*"
resource "vault_policy" "k8s_demo" {
  name   = "k8s-demo"
  policy = <<-EOT
    path "kv/data/app/*" {
      capabilities = ["read"]
    }
  EOT
}

# Role that maps K8s identities to Vault tokens with that policy
resource "vault_kubernetes_auth_backend_role" "workload_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "app-role"
  bound_service_account_names      = var.workload_service_accounts
  bound_service_account_namespaces = [var.workload_namespace]
  token_policies                   = [vault_policy.k8s_demo.name]
  token_ttl                        = 3600
  token_max_ttl                    = 7200
}
