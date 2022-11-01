locals {
  tags = merge(var.tags, { "type" = "storage", "used-by" = "zenml" })
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

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "main" {
  name                = "${var.location_code}-${var.environment}-${var.workload}-kv-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}
