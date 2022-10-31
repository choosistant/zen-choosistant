variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token with Zone-DNS-Edit and Zone-Zone-Read permissions, which is required for DNS01 challenge validation."
  sensitive   = true
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address that Let's Encrypt will use to send notifications about expiring certificates and account-related issues to."
  sensitive   = true
}
