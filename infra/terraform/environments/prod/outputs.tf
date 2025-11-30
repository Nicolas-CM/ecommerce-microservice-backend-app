output "resource_group_name" {
  description = "Resource group that hosts all prod resources."
  value       = module.resource_group.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster."
  value       = module.aks.id
}

output "aks_kube_config" {
  description = "Kubeconfig for AKS cluster access."
  value       = module.aks.kube_config
  sensitive   = true
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity."
  value       = module.aks.kubelet_identity_object_id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}


output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

# Monitoring Stack Outputs
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = module.monitoring.namespace
}

output "grafana_service_name" {
  description = "Grafana service name for port-forward"
  value       = module.monitoring.grafana_service_name
}

output "prometheus_service_name" {
  description = "Prometheus service name for port-forward"
  value       = module.monitoring.prometheus_service_name
}

output "kibana_service_name" {
  description = "Kibana service name for port-forward"
  value       = module.monitoring.kibana_service_name
}

output "elasticsearch_service_name" {
  description = "Elasticsearch service name for port-forward"
  value       = module.monitoring.elasticsearch_service_name
}

output "port_forward_commands" {
  description = "Commands to access monitoring services"
  value       = module.monitoring.port_forward_commands
}

output "ingress_public_ip" {
  description = "Public IP address for the ingress controller"
  value       = var.load_balancer_ip != "" ? var.load_balancer_ip : "Dynamic (check with kubectl get svc -n ingress-nginx)"
}

output "cert_manager_cluster_issuer" {
  description = "Cert-manager ClusterIssuer for production"
  value       = module.cert_manager.cluster_issuer_prod
}
