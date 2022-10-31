resource "helm_release" "reflector" {
  name             = "reflector"
  namespace        = var.namespace
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "reflector"
}
