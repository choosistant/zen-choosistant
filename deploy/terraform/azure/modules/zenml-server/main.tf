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
    name  = "ingress.className"
    value = "nginx"
  }

  set {
    name  = "ingress.host"
    value = var.ingress_host
  }

  set {
    name  = "ingress.path"
    value = "/"
  }

  set {
    name  = "zenml.rootUrlPath"
    value = "/"
  }

  set {
    name  = "zenml.defaultProject"
    value = var.default_project
  }

  set {
    name  = "zenml.defaultUsername"
    value = var.default_user_login
  }

  set {
    name  = "zenml.defaultPassword"
    value = var.default_user_password
  }
}
