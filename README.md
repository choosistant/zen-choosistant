# Choosistant on ZenML

A repo for creating ZenML pipelines for choosistant.

## Deploy on Azure

Login to Azure:

```bash
make azure-login
```

Create Azure resources for Terraform's remote backend and initialize Terraform.

```bash
make azure-terraform-init
```

Create Terraform plan:

```bash
make azure-terraform-plan
```

Deploy Azure resources:

```bash
make azure-terraform-apply
```

Setup Kubeconfig

```bash
make azure-terraform-kubeconfig > .aks-kubeconfig.yaml
export KUBECONFIG=$(pwd)/.aks-kubeconfig.yaml
```

Delete all Azure resources:

```bash
make azure-terraform-destroy
```
