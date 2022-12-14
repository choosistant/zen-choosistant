locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" })
}

terraform {
  required_version = ">= 1.1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.29.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.7.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>3.26.0"
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

module "letsencrypt-certs" {
  source                 = "./modules/letsencrypt-certs"
  cert_manager_namespace = module.cert-manager.namespace
  cloudflare_api_token   = var.cloudflare_api_token
  letsencrypt_email      = var.letsencrypt_email
}

# Configure the Cloudflare provider.
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "ingress-ctrl" {
  source              = "./modules/ingress-ctrl"
  domain_name         = var.ingress_controller_domain_name
  cluster_issuer_name = module.letsencrypt-certs.letsencrypt_issuer_name_production
}

module "label-studio" {
  source                = "./modules/label-studio"
  ingress_host          = var.label_studio_ingress_host
  default_user_email    = var.label_studio_default_user_email
  default_user_password = var.label_studio_default_user_password
  default_user_token    = var.label_studio_default_user_token
  depends_on = [
    module.ingress-ctrl
  ]
}

module "zenml-server" {
  source                = "./modules/zenml-server"
  ingress_host          = var.zenml_ingress_host
  default_project       = var.zenml_default_project
  default_user_login    = var.zenml_default_user_login
  default_user_password = var.zenml_default_user_password
  depends_on = [
    module.ingress-ctrl
  ]
}

module "zenml-stack" {
  source              = "./modules/zenml-stack"
  resource_group_name = azurerm_resource_group.main.name
  location_code       = var.location_code
  location            = var.location
  environment         = var.environment
  workload            = var.workload
  tags                = local.tags
}
