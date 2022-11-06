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

output "zenml_stack_storage_account_access_key_secret_name" {
  value = module.zenml-stack.storage_account_access_key_secret_name
}

output "zenml_stack_storage_account_access_key" {
  value     = module.zenml-stack.storage_account_access_key
  sensitive = true
}

output "label_studio_ingress_host" {
  value = module.label-studio.ingress_host
}

output "label_studio_default_user_email" {
  value = module.label-studio.default_user_email
}

output "label_studio_default_user_password" {
  value     = module.label-studio.default_user_password
  sensitive = true
}

output "label_studio_default_user_token" {
  value     = module.label-studio.default_user_token
  sensitive = true
}
