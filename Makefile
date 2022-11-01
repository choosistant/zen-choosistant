default:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  azure-login                 to login to Azure"
	@echo "  azure-terraform-init        to initialize Terraform"
	@echo "  azure-terraform-plan        to plan Terraform"
	@echo "  azure-terraform-apply       to deploy resources on Azure"
	@echo "  azure-terraform-destroy     to destroy all resources on Azure"

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

ZENML_STACK_NAME=choosistant-azure-stack
ZENML_SECRETS_MANAGER_NAME=choosistant-azure-secret-manager

zenml-init:
	@echo "Configure remote ZenML server..."
	@poetry run zenml connect --url https://zenml.sheikhomar.com/
	@poetry run zenml init

zenml-install-integrations:
	@echo "Installing ZenML integrations"
	@poetry run zenml integration install azure

zenml-create-stack:
	@echo "Creating ZenML stack..."
	$(eval CURRENT_STACK_NAME := $(shell poetry run zenml stack get | grep "active stack is:" | cut -d "'" -f 2))
	if [ "${CURRENT_STACK_NAME}" = "${ZENML_STACK_NAME}" ]; then \
		echo "Stack already exists"; \
	else \
		poetry run zenml stack copy default ${ZENML_STACK_NAME}; \
	fi
	@poetry run zenml stack set ${ZENML_STACK_NAME}

zenml-register-secrets-manager:
	@echo "Fetching key vault name from Azure..."
	@docker container run \
		-it \
		--rm \
		--mount type=bind,source="$(shell pwd)/deploy/terraform/azure",target=/workspace \
		--user $(shell id -u) \
		-v ${HOME}/.azure:/.azure \
		zenika/terraform-azure-cli:latest \
		terraform output --raw zenml_stack_key_vault_name \
		> /tmp/keyvault_name
	$(eval KEY_VAULT_NAME := $(file < /tmp/keyvault_name))
	@echo "Using key vault ${KEY_VAULT_NAME}"
	@poetry run zenml secrets-manager register ${ZENML_SECRETS_MANAGER_NAME} --key_vault_name=${KEY_VAULT_NAME} -f azure

dev-init:
	@poetry env use python
	@poetry install
	@poetry run pre-commit install

dev-precommit:
	poetry run pre-commit run --all-files
