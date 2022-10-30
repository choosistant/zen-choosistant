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
    value = "/zenml"
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
    value = "" # Use the default ingress class
  }
}
