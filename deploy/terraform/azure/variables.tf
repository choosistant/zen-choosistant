variable "location_code" {
  description = "The location code used in name of the resources e.g. euw."
  type        = string
  default     = "euw"
}

variable "location" {
  description = "The location for the resources e.g. West Europe."
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "The environment name used in the names of the resources e.g. dev, test, prod, etc"
  type        = string
  default     = "dev"
}

variable "workload" {
  description = "The workload name e.g. choos."
  type        = string
  default     = "choos"
}

variable "tags" {
  description = "Tags to apply to the resources."
  default     = {}
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

variable "zenml_default_password" {
  type        = string
  description = "The default password for the ZenML server."
  sensitive   = true
}
