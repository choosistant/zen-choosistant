PROJECT_DIR=$(realpath .)
ZENML_STACK_NAME=choosistant-azure-stack
ZENML_SECRETS_MANAGER_NAME=choosistant-azure-secret-manager
ZENML_AUTH_SECRET_NAME=choosistant-azure-auth-secret
ZENML_ARTIFICAT_STORE_NAME=choosistant-azure-artifact-store

function get_terraform_output() {
    docker container run \
        -it \
        --rm \
        --mount type=bind,source="$PROJECT_DIR/deploy/terraform/azure",target=/workspace \
        --user $(id -u) \
        -v ${HOME}/.azure:/.azure \
        zenika/terraform-azure-cli:latest \
        terraform output --raw $1
}
