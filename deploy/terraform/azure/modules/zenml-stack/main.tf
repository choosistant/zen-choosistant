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

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List",
    ]
  }
}

# Retrieve account key from storage account
data "azurerm_storage_account" "main" {
  name                = azurerm_storage_account.main.name
  resource_group_name = azurerm_storage_account.main.resource_group_name
}

# Create a secret containing the account key in the key vault
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = data.azurerm_storage_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
}
