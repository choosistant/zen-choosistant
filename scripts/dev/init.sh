#!/bin/bash
# This script initializes the development environment for the project.
#
# Usage:
#   ./scripts/dev/init.sh

set -e # Exit if any command fails

if ! hash python; then
    echo "Python is not installed. Consider installing Python via Pyenv: https://github.com/pyenv/pyenv"
    exit 1
fi

INSTALLED_PYTHON_VERSION=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
EXPECTED_PYTHON_VERSION=$(head -1 .python-version)

if [[ "$INSTALLED_PYTHON_VERSION" != "$EXPECTED_PYTHON_VERSION" ]]; then
    echo "Python version $INSTALLED_PYTHON_VERSION is installed, but $EXPECTED_PYTHON_VERSION is expected."
    echo "Consider installing Python $EXPECTED_PYTHON_VERSION via Pyenv: https://github.com/pyenv/pyenv"
    exit 1
else
    echo "Python version $INSTALLED_PYTHON_VERSION is installed."
fi

if ! hash poetry; then
    echo "Poetry is not installed. Please install Poetry first: https://python-poetry.org/"
    exit
fi

function get_cuda_version() {
    if hash /usr/local/cuda/bin/nvcc; then
        echo $(/usr/local/cuda/bin/nvcc --version | grep -Po '(?<=release )(.+)' | grep -Po '(.+)(?=,)' | tr -d '.')
    else
        echo ""
    fi
}

CUDA_VERSION=$(get_cuda_version)

if [[ "$CUDA_VERSION" == "" ]]; then
    POETRY_TORCH_GROUP_POSTFIX="cpu"
    echo "CUDA is not installed."
else
    POETRY_TORCH_GROUP_POSTFIX="cuda-$CUDA_VERSION"
    echo "CUDA is installed: $POETRY_TORCH_GROUP_POSTFIX."
fi

poetry env use python

echo "Installing dependencies..."
poetry install --with dev

echo "Installing pre-commit..."
poetry run pre-commit install
