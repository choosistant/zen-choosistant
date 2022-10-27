#/bin/bash

# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/variables.sh"

echo "Deleting all resources managed by Terraform..."
terraform destroy

# Clean up Terraform files
echo "Deleting resource group for Terraform backend $TF_RESOURCE_GROUP_NAME..."
az group delete --name $TF_RESOURCE_GROUP_NAME

echo "Deleting key vault $TF_KEY_VAULT_NAME..."
az keyvault purge --name $TF_KEY_VAULT_NAME

echo "Done!"
