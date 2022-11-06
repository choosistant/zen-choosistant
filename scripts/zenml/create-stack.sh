# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

echo "Creating ZenML stack..."
CURRENT_STACK_NAME=$(poetry run zenml stack get | grep "active stack is:" | cut -d "'" -f 2)
if [ "$CURRENT_STACK_NAME" = "$ZENML_STACK_NAME" ]; then
    echo "Stack already exists";
else
    poetry run zenml stack copy default $ZENML_STACK_NAME;
fi
poetry run zenml stack set $ZENML_STACK_NAME
