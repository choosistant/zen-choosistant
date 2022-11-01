output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "zenml_stack_key_vault_name" {
  value = module.zenml-stack.key_vault_name
}

output "zenml_stack_storage_account_name" {
  value = module.zenml-stack.storage_account_name
}

output "zenml_stack_storage_container_name" {
  value = module.zenml-stack.storage_container_name
}

output "zenml_stack_storage_blob_name" {
  value = module.zenml-stack.storage_blob_name
}
