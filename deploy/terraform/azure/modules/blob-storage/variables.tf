variable "resource_group_name" {
  description = "The name of the resource group to use for the Blob Storage."
  type        = string
}

variable "location_code" {
  description = "The location code used in name of the resources e.g. euw."
  type        = string
}

variable "location" {
  description = "The location for the resources e.g. West Europe."
  type        = string
}

variable "environment" {
  description = "The environment name used in the names of the resources e.g. dev, test, prod, etc"
  type        = string
  default     = "dev"
}

variable "workload" {
  description = "The workload name."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources."
  default     = {}
}
