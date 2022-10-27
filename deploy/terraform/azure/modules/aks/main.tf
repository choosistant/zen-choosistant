locals {
  tags = merge(var.tags, { "type" = "cluster" })
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.location_code}-${var.environment}-${var.workload}-sc-01"
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
