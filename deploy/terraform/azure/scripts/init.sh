#/bin/bash

# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/variables.sh"

echo "Creating resource group..."
az group create \
    --name $TF_RESOURCE_GROUP_NAME \
    --location westeurope

echo "Creating storage account..."
az storage account create \
    --resource-group $TF_RESOURCE_GROUP_NAME \
    --name $TF_STORAGE_ACCOUNT_NAME \
    --sku Standard_LRS \
    --encryption-services blob

echo "Creating Blob Storage container..."
az storage container create \
    --name $TF_CONTAINER_NAME \
    --account-name $TF_STORAGE_ACCOUNT_NAME

echo "Finding storage account key..."
ACCOUNT_KEY=$(az storage account keys list --resource-group $TF_RESOURCE_GROUP_NAME --account-name $TF_STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

echo "Creating key vault..."
az keyvault create \
    --name $TF_KEY_VAULT_NAME \
    --resource-group $TF_RESOURCE_GROUP_NAME \
    --location $TF_LOCATION

echo "Saving storage account key into the key vault..."
az keyvault secret set \
    --vault-name $TF_KEY_VAULT_NAME \
    --name $TF_KEY_NAME \
    --value $ACCOUNT_KEY

export ARM_ACCESS_KEY=$(az keyvault secret show --name $TF_KEY_NAME --vault-name $TF_KEY_VAULT_NAME --query value -o tsv)

echo "Initializing Terraform..."
terraform init

echo "Done."
