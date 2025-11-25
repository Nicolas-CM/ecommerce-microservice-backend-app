output "id" {
  value       = azurerm_container_app_environment.this.id
  description = "Container Apps environment resource ID."
}

output "default_domain" {
  value       = azurerm_container_app_environment.this.default_domain
  description = "Default FQDN for the environment."
}
