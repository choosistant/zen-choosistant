terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>3.26.0"
    }
  }
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "ingress-ctrl"
  }
}

resource "helm_release" "nginx" {
  name             = "nginx-ingress"
  namespace        = kubernetes_namespace.nginx.metadata.0.name
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "nginx-ingress"

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }
}

# Pull information about the nginx service because we need
# to output the external IP address of the service.
data "kubernetes_service" "nginx" {
  metadata {
    name      = "${helm_release.nginx.name}-${helm_release.nginx.name}"
    namespace = helm_release.nginx.namespace
  }
}

data "cloudflare_zones" "main" {
  filter {
    name = var.domain_name
  }
}

# Add a DNS record which points to the external IP of the nginx service.
resource "cloudflare_record" "wildcard_record" {
  zone_id = data.cloudflare_zones.main.zones.0.id
  name    = "*.${var.domain_name}"
  type    = "A"
  value   = data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
  proxied = false
}
