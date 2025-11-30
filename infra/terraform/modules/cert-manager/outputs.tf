output "namespace" {
  description = "Namespace de cert-manager"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "cluster_issuer_prod" {
  description = "Nombre del ClusterIssuer de producción"
  value       = "letsencrypt-prod"
}

output "cluster_issuer_staging" {
  description = "Nombre del ClusterIssuer de staging"
  value       = "letsencrypt-staging"
}
