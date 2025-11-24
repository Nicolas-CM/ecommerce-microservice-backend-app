output "network_name" {
  description = "Name of the VPC network created for this environment."
  value       = module.network.network_name
}

output "artifact_registry_repository" {
  description = "Full resource name of the Artifact Registry repository."
  value       = module.artifact_registry.repository_resource
}

output "cloud_run_urls" {
  description = "Endpoint URLs for each deployed Cloud Run service."
  value = {
    for service_name, service_module in module.cloud_run_service :
    service_name => service_module.url
  }
}
