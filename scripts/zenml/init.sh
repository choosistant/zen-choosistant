# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

echo "ZenML initialization procedure started."

echo " - Retrieving the hostname of the remote ZenML server..."
export ZENML_HOST_NAME=$(get_terraform_output zenml_server_ingress_host)

echo " - Retrieving the login name..."
export ZENML_USER_NAME=$(get_terraform_output zenml_server_default_user_login)

echo " - Retrieving the login password..."
export ZENML_PASSWORD=$(get_terraform_output zenml_server_default_user_password)

export ZENML_REMOTE_URL="https://$ZENML_HOST_NAME/"

echo " - Connecting to ZenML $ZENML_REMOTE_URL with $ZENML_USER_NAME..."
poetry run zenml connect \
    --url $ZENML_REMOTE_URL \
    --username $ZENML_USER_NAME \
    --password $ZENML_PASSWORD

echo " - Initializing ZenML..."
poetry run zenml init

echo " ✔️ ZenML initialized."
