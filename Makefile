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

dev-init:
	@poetry env use python
	@poetry install
	@poetry run pre-commit install

dev-precommit:
	poetry run pre-commit run --all-files
