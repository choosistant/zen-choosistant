# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

echo "Label Studio registration procedure started."

echo " - Retrieving Label Studio hostname..."
export LABEL_STUDIO_HOST_NAME=$(get_terraform_output label_studio_ingress_host)

echo " - Retrieving Label Studio API key..."
export LABEL_STUDIO_API_KEY=$(get_terraform_output label_studio_default_user_token)

# Workaround: ZenML fails to register annotator if the port
# specificed with the --port option is not available in the
# local machine, even though the annotator is running on
# a remove server.
if [ -z "$LABEL_STUDIO_PORT" ]; then
    export LABEL_STUDIO_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
fi

echo " - Storing Label Studio API key in the secret: '$ZENML_LABEL_STUDIO_SECRET_NAME' ..."
poetry run zenml secrets-manager secret register $ZENML_LABEL_STUDIO_SECRET_NAME \
    --api_key="$LABEL_STUDIO_API_KEY"

echo " - Registering annotator in ZenML with the name $ZENML_LABEL_STUDIO_NAME..."
poetry run zenml annotator register $ZENML_LABEL_STUDIO_NAME \
    --flavor label_studio \
    --authentication_secret=$ZENML_LABEL_STUDIO_SECRET_NAME \
    --instance_url="https://$LABEL_STUDIO_HOST_NAME" \
    --port=$LABEL_STUDIO_PORT

echo " - Updating the stack with the annotator..."
poetry run zenml stack update $ZENML_STACK_NAME \
    -an $ZENML_LABEL_STUDIO_NAME

echo " ✔️ Label Studio registration procedure completed."
