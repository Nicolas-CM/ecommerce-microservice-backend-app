variable "name" {
  description = "Name of the Container Apps environment."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the environment."
  type        = string
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID delegated to Microsoft.App/environments."
  type        = string
}

variable "internal_load_balancer_enabled" {
  description = "Whether to enable an internal load balancer."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the environment."
  type        = map(string)
  default     = {}
}
