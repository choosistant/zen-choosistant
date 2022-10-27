locals {
  tags = merge(var.tags, { "type" = "storage" })
}

resource "azurerm_storage_account" "main" {
  name                     = "${var.location_code}${var.environment}${var.workload}st01"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_container" "main" {
  name                  = "${var.location_code}-${var.environment}-${var.workload}-sc-01"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "main" {
  name                   = "${var.location_code}-${var.environment}-${var.workload}-bs-01"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.main.name
  type                   = "Block"
}
