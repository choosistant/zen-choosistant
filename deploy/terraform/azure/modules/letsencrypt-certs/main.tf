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
      name = "letsencrypt-staging"
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
      name = "letsencrypt-production"
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
