# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

echo "ZenML secret manager registration procedure started."

echo " - Retrieving key vault name from Azure..."
export KEY_VAULT_NAME=$(get_terraform_output zenml_stack_key_vault_name)
echo " - Using key vault: $KEY_VAULT_NAME"

echo " - Registering secret manager $ZENML_SECRETS_MANAGER_NAME using Azure Key Vault $KEY_VAULT_NAME..."
poetry run zenml secrets-manager register $ZENML_SECRETS_MANAGER_NAME \
    --key_vault_name=$KEY_VAULT_NAME \
    -f azure

echo " - Updating the stack with the secret manager..."
poetry run zenml stack update $ZENML_STACK_NAME \
    -x $ZENML_SECRETS_MANAGER_NAME

echo " ✔️ ZenML secret manager registration procedure completed."
