resource "kubernetes_namespace" "label_studio" {
  metadata {
    name = "label-studio"
  }
}

resource "helm_release" "label_studio" {
  name             = "label-studio"
  namespace        = kubernetes_namespace.label_studio.metadata.0.name
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "label-studio"

  set {
    name  = "ingress.host"
    value = var.ingress_host
  }

  set {
    name  = "default_user.email"
    value = var.default_user_email
  }

  set {
    name  = "default_user.password"
    value = var.default_user_password
  }

  set {
    name  = "default_user.token"
    value = var.default_user_token
  }
}
