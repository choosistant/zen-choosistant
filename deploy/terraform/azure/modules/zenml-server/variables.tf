variable "default_password" {
  description = "The default password for the ZenML server."
  type        = string
  sensitive   = true
}

variable "ingress_host" {
  description = "The ingress host for the ZenML server."
  type        = string
}
