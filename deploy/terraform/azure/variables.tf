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
