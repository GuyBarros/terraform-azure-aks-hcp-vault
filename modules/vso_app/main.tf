
# (Optional) Example CRD to sync kv/app/demo -> Secret app-demo in your workload namespace
# Requires the Kubernetes provider to support kubernetes_manifest (2.29+).
resource "kubernetes_namespace" "workload" {
  metadata { name = var.workload_namespace }
}



resource "kubernetes_manifest" "vso_static_secret" {
 depends_on = [ kubernetes_namespace.workload ]
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultStaticSecret"
    metadata = {
      name      = "app-demo"
      namespace = var.workload_namespace
    }
    spec = {
      vaultAuthRef       = "${var.vso_namespace}/default"
      type               = "kv-v2"
      mount              = "kv"
      path               = "app"
      destination = {
        name   = "app-demo"
        create = true
        type   = "Opaque"
      }
    }
  }
}

# kubectl describe VaultStaticSecret app-demo -n demo