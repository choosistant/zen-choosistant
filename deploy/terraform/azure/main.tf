locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" })
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.28.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.7.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "euw-dev-chotf-rg-01"
    storage_account_name = "euwdevchotfst01"
    container_name       = "euw-dev-chotf-sc-01"
    key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.location_code}-${var.environment}-${var.workload}-rg-01"
  location = var.location
  tags     = local.tags
}

# Create blog storage
module "blob-storage" {
  source              = "./modules/blob-storage"
  resource_group_name = azurerm_resource_group.main.name
  location_code       = var.location_code
  location            = var.location
  environment         = var.environment
  workload            = var.workload
  tags                = local.tags
}

# Create Azure Kubernetes Service
module "aks" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.main.name
  location_code       = var.location_code
  location            = var.location
  environment         = var.environment
  workload            = var.workload
  tags                = local.tags
}

module "k8s-resources" {
  source                     = "./modules/k8s-resources"
  k8s_host                   = module.aks.host
  k8s_client_certificate     = module.aks.client_certificate
  k8s_client_key             = module.aks.client_key
  k8s_cluster_ca_certificate = module.aks.cluster_ca_certificate
}
