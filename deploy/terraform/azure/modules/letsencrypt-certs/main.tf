locals {
  letsencrypt_issuer_name_staging          = "letsencrypt-staging"
  letsencrypt_issuer_name_production       = "letsencrypt-production"
  sheikhomar_com_wildcard_cert_secret_name = "letsencrypt-wildcard-cert-sheikhomar.com"
}

# Create a secret in the cert-manager's namespace and
# store the CloudFlare API token.
resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = var.cert_manager_namespace
  }

  data = {
    "api-token" = var.cloudflare_api_token
  }
}

resource "kubernetes_manifest" "letsencrypt_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.letsencrypt_issuer_name_staging
    }
    spec = {
      acme = {
        email = var.letsencrypt_email
        privateKeySecretRef = {
          name = "issuer-account-key-letsencrypt-staging"
        }
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = kubernetes_secret.cloudflare_api_token.metadata.0.name
                  key  = keys(kubernetes_secret.cloudflare_api_token.data).0
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_production" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = local.letsencrypt_issuer_name_production
    }
    spec = {
      acme = {
        email = var.letsencrypt_email
        privateKeySecretRef = {
          name = "issuer-account-key-letsencrypt-production"
        }
        server = "https://acme-v02.api.letsencrypt.org/directory"
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = kubernetes_secret.cloudflare_api_token.metadata.0.name
                  key  = keys(kubernetes_secret.cloudflare_api_token.data).0
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_wildcard_cert_sheikhomar_com" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "letsencrypt-wildcard-cert-sheikhomar.com"
      namespace = var.cert_manager_namespace
      annotations = {
        "reflector.v1.k8s.emberstack.com/reflection-allowed"            = "true"
        "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces" = ""
        "reflector.v1.k8s.emberstack.com/reflection-auto-enabled"       = "true"
        "reflector.v1.k8s.emberstack.com/reflection-auto-namespaces"    = ""
      }
    }
    spec = {
      secretName = local.sheikhomar_com_wildcard_cert_secret_name
      issuerRef = {
        name = local.letsencrypt_issuer_name_production
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "sheikhomar.com",
        "*.sheikhomar.com"
      ]
    }
  }
}
