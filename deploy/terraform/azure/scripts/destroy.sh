#/bin/bash

# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/variables.sh"

# Clean up
echo "Deleting resource group $TF_RESOURCE_GROUP_NAME..."
az group delete --name $TF_RESOURCE_GROUP_NAME

echo "Deleting key vault $TF_KEY_VAULT_NAME..."
az keyvault purge --name $TF_KEY_VAULT_NAME

echo "Done!"
