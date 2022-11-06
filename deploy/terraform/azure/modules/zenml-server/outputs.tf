output "ingress_host" {
  value = var.ingress_host
}

output "default_project" {
  value = var.default_project
}

output "default_user_login" {
  value     = var.default_user_login
  sensitive = true
}

output "default_user_password" {
  value     = var.default_user_password
  sensitive = true
}
