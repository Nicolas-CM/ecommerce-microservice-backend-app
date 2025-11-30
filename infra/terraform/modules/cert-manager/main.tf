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

# Namespace para cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
}

# Instalación de cert-manager con Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.3"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager.metadata[0].name
  }

  timeout = 600

  depends_on = [kubernetes_namespace.cert_manager]
}

# Esperar a que cert-manager esté listo
resource "time_sleep" "wait_for_cert_manager" {
  create_duration = "60s"

  depends_on = [helm_release.cert_manager]
}

# ClusterIssuers usando Helm chart local
resource "helm_release" "cluster_issuers" {
  name      = "cluster-issuers"
  chart     = "${path.module}/cluster-issuer-chart"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "email"
    value = var.email
  }

  depends_on = [time_sleep.wait_for_cert_manager]
}
