variable "name" {
  description = "Name of the Azure Container Registry."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the registry will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "sku" {
  description = "SKU of the registry (Basic, Standard, Premium)."
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Whether to enable the admin user."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}
