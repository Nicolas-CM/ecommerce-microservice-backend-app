output "resource_group_name" {
  description = "Resource group that hosts all dev resources."
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
