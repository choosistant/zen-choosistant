locals {
  tags = merge(var.tags, { "type" = "cluster" })
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.location_code}-${var.environment}-${var.workload}-aks-01"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "choosistant-k8s"
  tags                = local.tags

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_B2ms"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}

data "azurerm_kubernetes_cluster" "main" {
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_kubernetes_cluster.main.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "main" {
  metadata {
    name = "choosistant"
  }
}
