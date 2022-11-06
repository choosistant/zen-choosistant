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

variable "zenml_ingress_host" {
  type        = string
  description = "The ingress host for the ZenML server."
}

variable "zenml_default_project" {
  type        = string
  description = "The default project for the ZenML server."
}

variable "zenml_default_user_login" {
  type        = string
  description = "The default user login for the ZenML server."
  sensitive   = true
}

variable "zenml_default_user_password" {
  type        = string
  description = "The default password for the ZenML server."
  sensitive   = true
}

variable "ingress_controller_domain_name" {
  type        = string
  description = "The domain name for the ingress controller."
}

variable "label_studio_ingress_host" {
  type        = string
  description = "The ingress host for the Label Studio server."
}

variable "label_studio_default_user_email" {
  type        = string
  description = "The login name of the default user."
}

variable "label_studio_default_user_password" {
  type        = string
  description = "The password of the default user."
  sensitive   = true
}

variable "label_studio_default_user_token" {
  type        = string
  description = "The token of the default user. This is used to authenticate the user when using the Label Studio API."
  sensitive   = true
}
