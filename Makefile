default:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  azure-login                 to login to Azure"
	@echo "  azure-terraform-init        to initialize Terraform"
	@echo "  azure-terraform-plan        to plan Terraform"
	@echo "  azure-terraform-apply       to deploy resources on Azure"
	@echo "  azure-terraform-destroy     to destroy all resources on Azure"

COLOR_GREEN='\033[0;31m'
COLOR_RED='\033[0;32m'
COLOR_NONE='\033[0m'

azure-login:
	docker container run \
		-it \
		--rm \
		-v ${HOME}/.azure:/home/nonroot/.azure \
		zenika/terraform-azure-cli:latest \
		az login

azure-terraform-init:
	@echo "Initializing Terraform"
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		bash /workspace/scripts/init.sh

azure-terraform-plan:
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		terraform plan

azure-terraform-apply:
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		terraform apply

azure-terraform-destroy:
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		bash /workspace/scripts/destroy.sh

configure-kubectl:
	echo "Fetching kubeconfig from AKS..."
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		terraform output kube_config \
		| grep -v "EOT" > ${HOME}/.kube/config
	@chmod go-r ~/.kube/config
	@echo "Setting default namespace to choosistant..."
	@kubectl config set-context --current --namespace=choosistant

zenml-init:
	@echo "Configure remote ZenML server..."
	@poetry run zenml connect --url https://zenml.sheikhomar.com/
	@poetry run zenml init

zenml-install-integrations:
	@echo "Installing ZenML integrations"
	@poetry run zenml integration install azure

zenml-create-stack:
	bash $(shell pwd)/scripts/zenml/create-stack.sh

zenml-register-secrets-manager:
	bash $(shell pwd)/scripts/zenml/register-secret-manager.sh

zenml-register-artifact-store:
	bash $(shell pwd)/scripts/zenml/register-artifact-store.sh

guard-%:
	@if [ -z '${${*}}' ]; then \
		echo 'Environment variable $* not set.'; \
		echo 'Please call the make target with $*="value".'; \
		exit 1; \
	fi

zenml-update-chart: guard-VERSION
	@bash $(shell pwd)/scripts/zenml/update-chart.sh $(VERSION)

dev-init:
	@poetry env use python
	@poetry install
	@poetry run pre-commit install

dev-precommit:
	poetry run pre-commit run --all-files
