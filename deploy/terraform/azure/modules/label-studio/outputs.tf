
output "ingress_host" {
  value = var.ingress_host
}

output "default_user_email" {
  value = var.default_user_email
}

output "default_user_password" {
  value     = var.default_user_password
  sensitive = true
}

output "default_user_token" {
  value     = var.default_user_token
  sensitive = true
}
