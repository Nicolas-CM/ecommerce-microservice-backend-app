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

# Namespace para monitoreo
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = "production"
    }
  }
}

# ============================================================================
# PROMETHEUS + GRAFANA (kube-prometheus-stack)
# ============================================================================
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "default"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
        }
      }

      grafana = {
        enabled       = true
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = false
        }
        service = {
          type = "ClusterIP"
        }
      }

      alertmanager = {
        enabled = true
      }

      kubeStateMetrics = {
        enabled = true
      }

      nodeExporter = {
        enabled = true
      }
    })
  ]

  timeout = 1200
  wait    = false

  depends_on = [kubernetes_namespace.monitoring]
}