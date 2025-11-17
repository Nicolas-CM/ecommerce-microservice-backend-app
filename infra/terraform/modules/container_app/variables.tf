variable "name" {
  description = "Name of the Container App."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the Container App."
  type        = string
}

variable "location" {
  description = "Azure region for the Container App."
  type        = string
}

variable "environment_id" {
  description = "Container Apps environment ID."
  type        = string
}

variable "image" {
  description = "Container image to deploy."
  type        = string
}

variable "registry_server" {
  description = "Container registry server."
  type        = string
}

variable "registry_username" {
  description = "Container registry username."
  type        = string
}

variable "registry_password" {
  description = "Container registry password."
  type        = string
  sensitive   = true
}

variable "cpu" {
  description = "vCPU requested for the container."
  type        = number
  default     = 0.5
}

variable "memory_gb" {
  description = "Memory requested (Gi)."
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables injected into the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of secret name/value pairs for the Container App."
  type        = map(string)
  default     = {}
}

variable "min_replicas" {
  description = "Minimum number of replicas."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas."
  type        = number
  default     = 2
}

variable "revision_mode" {
  description = "Revision mode (Single or Multiple)."
  type        = string
  default     = "Single"
}

variable "ingress" {
  description = "Ingress configuration for the Container App."
  type = object({
    external_enabled           = bool
    target_port                = number
    transport                  = optional(string, "auto")
    allow_insecure_connections = optional(bool, false)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to the Container App."
  type        = map(string)
  default     = {}
}
