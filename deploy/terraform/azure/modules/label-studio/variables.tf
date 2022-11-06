variable "ingress_host" {
  description = "The ingress host for the ZenML server."
  type        = string
}

variable "default_user_email" {
  description = "The login name of the default user."
  type        = string
}

variable "default_user_password" {
  description = "The password of the default user."
  type        = string
  sensitive   = true
}

variable "default_user_token" {
  description = "The token of the default user. This is used to authenticate the user when using the Label Studio API."
  type        = string
  sensitive   = true
}
