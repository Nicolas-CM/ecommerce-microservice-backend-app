output "namespace" {
  description = "Namespace de ingress-nginx"
  value       = kubernetes_namespace.ingress_nginx.metadata[0].name
}

output "ingress_class_name" {
  description = "Nombre de la clase de ingress"
  value       = "nginx"
}
