terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>3.26.0"
    }
  }
}

locals {
  wildcard_domain_cert_name        = "${var.domain_name}-wildcard-cert"
  wildcard_domain_cert_secret_name = "${var.domain_name}-wildcard-cert-secret"
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "ingress-ctrl"
  }
}

resource "kubernetes_manifest" "wildcard_cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.wildcard_domain_cert_name
      namespace = kubernetes_namespace.nginx.metadata.0.name
    }
    spec = {
      secretName = local.wildcard_domain_cert_secret_name
      issuerRef = {
        name = var.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        var.domain_name,
        "*.${var.domain_name}"
      ]
    }
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

  set {
    name = "controller.extraArgs.default-ssl-certificate"
    value = "${kubernetes_namespace.nginx.metadata.0.name}/${local.wildcard_domain_cert_secret_name}"
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
