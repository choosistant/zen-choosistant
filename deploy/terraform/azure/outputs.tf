output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
