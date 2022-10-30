locals {
  rootUrlPath = "/zenml"
}

resource "kubernetes_namespace" "zenml" {
  metadata {
    name = "zenml"
  }
}

resource "helm_release" "zenml" {
  name             = "zenml"
  namespace        = kubernetes_namespace.zenml.metadata.0.name
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "zenml"

  set {
    name  = "zenml.rootUrlPath"
    value = local.rootUrlPath
  }

  set {
    name  = "zenml.defaultProject"
    value = "choosistant"
  }

  set {
    name  = "zenml.defaultUsername"
    value = "choosistant"
  }

  set {
    name  = "zenml.defaultPassword"
    value = var.default_password
  }

  set {
    name  = "ingress.className"
    value = "traefik"
  }

  set {
    name  = "ingress.host"
    value = var.ingress_host
  }

  set {
    name  = "ingress.path"
    value = local.rootUrlPath
  }

  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
    value = "websecure"
  }
}
