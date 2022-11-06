variable "ingress_host" {
  description = "The ingress host for the ZenML server."
  type        = string
}

variable "default_project" {
  description = "The default project for the ZenML server."
  type        = string
}

variable "default_user_login" {
  description = "The default user login for the ZenML server."
  type        = string
  sensitive   = true
}

variable "default_user_password" {
  description = "The default password for the ZenML server."
  type        = string
  sensitive   = true
}
