output "id" {
  value       = azurerm_log_analytics_workspace.this.id
  description = "Workspace resource ID."
}

output "customer_id" {
  value       = azurerm_log_analytics_workspace.this.workspace_id
  description = "Workspace customer ID."
}

output "primary_shared_key" {
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  description = "Primary shared key for the workspace."
  sensitive   = true
}
