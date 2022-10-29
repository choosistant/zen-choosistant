# Create the default namespace.
resource "kubernetes_namespace" "main" {
  metadata {
    name = "choosistant"
  }
}

# Create namespace for the cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = kubernetes_namespace.cert_manager.metadata.0.name
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "cert-manager"
}
