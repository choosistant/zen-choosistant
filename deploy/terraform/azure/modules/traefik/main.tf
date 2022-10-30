terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>3.26.0"
    }
  }
}

locals {
  sheikhomar_com_wildcard_cert_name        = "sheikhomar.com-wildcard-cert"
  sheikhomar_com_wildcard_cert_secret_name = "sheikhomar.com-wildcard-cert-secret"
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = kubernetes_namespace.traefik.metadata.0.name
  create_namespace = false
  repository       = "${path.module}/charts"
  chart            = "traefik"

  set {
    name  = "ports.web.redirectTo"
    value = "websecure"
  }

  # Trust private AKS IP range
  set {
    name  = "additionalArguments"
    value = "{--entryPoints.websecure.forwardedHeaders.trustedIPs=10.0.0.0/8}"
  }
}

# Pull information about the Traefik service because we need
# the external IP address of the Traefik service to create a
# new DNS record for our domain.
data "kubernetes_service" "traefik" {
  metadata {
    name      = helm_release.traefik.name
    namespace = helm_release.traefik.namespace
  }
}

data "cloudflare_zones" "sheikhomar_com" {
  filter {
    name = "sheikhomar.com"
  }
}

# Add a DNS record which points to the external IP of the Traefik service.
resource "cloudflare_record" "traefik" {
  zone_id = data.cloudflare_zones.sheikhomar_com.zones.0.id
  name    = "choosistant-aks"
  type    = "A"
  value   = data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip
  proxied = false
}

resource "kubernetes_manifest" "wildcard_cert_sheikhomar_com" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.sheikhomar_com_wildcard_cert_name
      namespace = helm_release.traefik.namespace
    }
    spec = {
      secretName = local.sheikhomar_com_wildcard_cert_secret_name
      issuerRef = {
        name = var.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "sheikhomar.com",
        "*.sheikhomar.com"
      ]
    }
  }
}

# Create a default TLSStore which contains the wildcard certificate.
resource "kubernetes_manifest" "tls_store_sheikhomar_com" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "TLSStore"
    metadata = {
      # Traefik currently only uses the TLS Store named "default".
      name      = "default"
      namespace = helm_release.traefik.namespace
    }
    spec = {
      defaultCertificate = {
        secretName = local.sheikhomar_com_wildcard_cert_secret_name
      }
    }
  }
}
