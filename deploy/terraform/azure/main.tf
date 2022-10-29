locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" })
}

terraform {
  required_version = ">= 1.1.5"

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

# Configure the Kubernetes provider.
provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

# Configure the Helm provider.
provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

module "cert-manager-crds" {
  source = "./modules/cert-manager-crds"
  depends_on = [
    module.aks
  ]
}

module "cert-manager" {
  source = "./modules/cert-manager"
  depends_on = [
    module.cert-manager-crds
  ]
}
