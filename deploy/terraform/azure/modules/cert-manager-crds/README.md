# CRDs for cert-manager

We need to create CustomResourceDefinition resources required by  `cert-manager` before installing the `cert-manager` chart itself. In this project, we use CRDs for v1.10.0. We convert the CRDs YAML file containing multiple manifests into Terraform file using `tfk8s`:

```bash
wget https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.crds.yaml
tfk8s -f cert-manager.crds.yaml -o cert-manager.crds.tf
```
