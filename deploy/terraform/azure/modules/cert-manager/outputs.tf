output "namespace" {
  value = kubernetes_namespace.cert_manager.metadata.0.name
}
