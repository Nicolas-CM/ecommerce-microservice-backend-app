variable "subscription_id" {
  description = "Azure subscription ID to deploy resources to."
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "global_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "environment_name" {
  description = "Deployment environment identifier (dev, stage, prod)."
  type        = string
}

variable "image_tag" {
  description = "Docker image tag applied to all services by default."
  type        = string
}

variable "network_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "containerapps_subnet_cidr" {
  description = "CIDR assigned to the Container Apps delegated subnet."
  type        = string
}

variable "log_analytics_retention_days" {
  description = "Retention period for Log Analytics workspace."
  type        = number
  default     = 30
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry."
  type        = string
  default     = "Premium"
}

variable "caenv_internal_lb" {
  description = "Enable internal only Container Apps environment ingress."
  type        = bool
  default     = true
}

variable "service_definitions" {
  description = "Map describing each microservice deployment details."
  type        = map(any)
  default     = {}
}

variable "default_environment_variables" {
  description = "Environment variables applied to every service."
  type        = map(string)
  default     = {}
}

variable "default_secrets" {
  description = "Secrets applied to every service deployment."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Global tags applied to all resources."
  type        = map(string)
  default     = {}
}
