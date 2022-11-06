# exit when any command fails
set -e

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/common.sh"

ZENML_VERSION=$1

# exit if ZENML_VERSION is not set
if [ -z "$ZENML_VERSION" ]; then
    echo "No ZenML version specified. is not set. Please provide a ZenML version."
    exit 1
fi

DOWNLOAD_URL=https://github.com/zenml-io/zenml/archive/refs/tags/$ZENML_VERSION.zip
echo "Downloading ZenML version $ZENML_VERSION from $DOWNLOAD_URL"
rm -rf /tmp/zenml /tmp/zenml.zip
mkdir -p /tmp/zenml
curl -L -o /tmp/zenml.zip $DOWNLOAD_URL
unzip -oq /tmp/zenml.zip -d /tmp/zenml

# copy the zenml folder to the helm chart
echo "Copying ZenML Helm chart..."
SRC_DIR=/tmp/zenml/zenml-$ZENML_VERSION/src/zenml/zen_server/deploy/helm
DEST_DIR=deploy/terraform/azure/modules/zenml-server/charts/zenml
rm -rf $DEST_DIR
mkdir -p $DEST_DIR
cp -rf $SRC_DIR/* $DEST_DIR

echo "Done."
