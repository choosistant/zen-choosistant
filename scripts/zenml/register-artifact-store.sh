# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

echo "ZenML artifact store registration procedure started."

echo " - Retrieving storage account name from Azure..."
export STORAGE_ACCOUNT_NAME=$(get_terraform_output zenml_stack_storage_account_name)

echo " - Retrieving storage account key from Azure..."
export STORAGE_ACCOUNT_KEY=$(get_terraform_output zenml_stack_storage_account_access_key)

echo " - Retrieving storage container name from Azure..."
export STORAGE_CONTAINER_NAME=$(get_terraform_output zenml_stack_storage_container_name)

export AZURE_CONFIG_DIR="$HOME/.azure"

echo " - Registering authentication secret $ZENML_AUTH_SECRET_NAME for account $STORAGE_ACCOUNT_NAME..."
poetry run zenml secrets-manager secret register $ZENML_AUTH_SECRET_NAME \
    --schema=azure \
    --account_name=$STORAGE_ACCOUNT_NAME \
    --account_key=$STORAGE_ACCOUNT_KEY

echo " - Registering Azure artifact store $ZENML_ARTIFICAT_STORE_NAME..."
poetry run zenml artifact-store register $ZENML_ARTIFICAT_STORE_NAME \
    -f azure \
    --path="az://$STORAGE_CONTAINER_NAME" \
    --authentication_secret=$ZENML_AUTH_SECRET_NAME

echo " - Updating stack with the artifact store..."
poetry run zenml stack update $ZENML_STACK_NAME \
    -a $ZENML_ARTIFICAT_STORE_NAME

echo " ✔️ ZenML artifact store registration procedure completed."
