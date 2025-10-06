# Discover your current public IP (for API server allow-list)
data "http" "myip" {
  url = "https://ifconfig.me"
}



# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "guy_aks"
  location = var.location
}

# Random suffix to keep cluster name unique
resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "guy-aks-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "guy-aks-${random_string.suffix.result}"

  kubernetes_version = var.kubernetes_version

  # Keep this enabled so kubectl/helm can auth easily with the emitted kubeconfig.
  # Set to true to disable local admin & enforce AAD-only.
  local_account_disabled = !var.enable_local_admin

  # RBAC on (recommended)
  role_based_access_control_enabled = true

  default_node_pool {
    name            = "system"
    node_count      = var.node_count
    vm_size         = var.vm_size
    type            = "VirtualMachineScaleSets"
    orchestrator_version = var.kubernetes_version
    os_disk_size_gb = 128
    upgrade_settings {
      max_surge = "33%"
    }
  }

  # Network profile (Azure CNI for pod IPs on VNET)
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Lock down access to the API server to your IP (or provided CIDR)
  api_server_access_profile {
    authorized_ip_ranges = var.client_ip_cidrs
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    owner = "guy"
    env   = "dev"
  }
}
