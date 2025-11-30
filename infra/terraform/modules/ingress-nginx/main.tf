terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Namespace para ingress-nginx
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

# Instalación de ingress-nginx con Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = var.load_balancer_ip != "" ? {
            "service.beta.kubernetes.io/azure-load-balancer-resource-group" = var.static_ip_resource_group
            "service.beta.kubernetes.io/azure-pip-name"                     = "ecommerce-prod-ip"
          } : {}
          loadBalancerIP = var.load_balancer_ip != "" ? var.load_balancer_ip : null
        }

        metrics = {
          enabled = true
          serviceMonitor = {
            enabled   = true
            namespace = "monitoring"
          }
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        config = {
          use-forwarded-headers = "true"
          compute-full-forwarded-for = "true"
          use-proxy-protocol = "false"
        }

        # Configuración de logs para ELK
        extraArgs = {
          default-ssl-certificate = "prod/ecommerce-tls-prod"
        }
      }

      defaultBackend = {
        enabled = true
      }
    })
  ]

  timeout = 600

  depends_on = [kubernetes_namespace.ingress_nginx]
}

# Esperar a que el ingress controller esté listo
resource "time_sleep" "wait_for_ingress" {
  create_duration = "60s"

  depends_on = [helm_release.ingress_nginx]
}
