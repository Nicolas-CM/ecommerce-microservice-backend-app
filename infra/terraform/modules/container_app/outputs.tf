output "name" {
  value       = azurerm_container_app.this.name
  description = "Container App name."
}

output "fqdn" {
  value       = try(azurerm_container_app.this.ingress[0].fqdn, null)
  description = "Ingress FQDN (if ingress enabled)."
}
