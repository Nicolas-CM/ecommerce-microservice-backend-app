output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "Registry login server URI."
}

output "admin_username" {
  value       = azurerm_container_registry.this.admin_username
  description = "Admin username for the registry."
}

output "admin_password" {
  value       = azurerm_container_registry.this.admin_password
  description = "Admin password for the registry."
  sensitive   = true
}

output "id" {
  value       = azurerm_container_registry.this.id
  description = "The ID of the Container Registry."
}
