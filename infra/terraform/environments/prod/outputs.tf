output "resource_group_name" {
  description = "Resource group that hosts all prod resources."
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
