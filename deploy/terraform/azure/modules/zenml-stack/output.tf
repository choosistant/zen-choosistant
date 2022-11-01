output "storage_account_name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.main.name
}

output "storage_account_access_key_secret_name" {
  description = "The name of the secret containing the storage account key."
  value       = azurerm_key_vault_secret.storage_account_key.name
}

output "storage_account_access_key" {
  description = "The primary access key for the storage account."
  value       = data.azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_container_name" {
  description = "The name of the storage container."
  value       = azurerm_storage_container.main.name
}

output "storage_blob_name" {
  description = "The name of the storage blob."
  value       = azurerm_storage_blob.main.name
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.main.name
}
