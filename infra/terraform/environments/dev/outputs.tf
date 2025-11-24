output "resource_group_name" {
  description = "Resource group that hosts all dev resources."
  value       = module.resource_group.name
}

output "acr_login_server" {
  description = "ACR login server for pushing microservice images."
  value       = module.acr.login_server
}

output "container_app_fqdns" {
  description = "Map of service names to their exposed FQDNs."
  value = {
    for name, details in module.container_apps :
    name => details.fqdn
  }
}

# AKS Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster."
  value       = module.aks.cluster_id
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
