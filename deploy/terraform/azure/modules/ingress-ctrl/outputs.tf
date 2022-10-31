output "namespace" {
  value = kubernetes_namespace.nginx.metadata.0.name
}

output "load_balancer_ip" {
  value = data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
}
