# This file mirrors the dev variables; customize values through terraform.tfvars
variable "project_id" {
  type        = string
  description = "GCP project ID used for this environment."
}

variable "region" {
  type        = string
  description = "Primary region for resources (Cloud Run, subnets, Artifact Registry)."
}

variable "global_prefix" {
  type        = string
  description = "Short identifier shared across environments (e.g. eco)."
}

variable "environment_name" {
  type        = string
  description = "Environment identifier (dev, stage, prod)."
}

variable "image_tag" {
  type        = string
  description = "Default image tag used when building image names automatically."
  default     = "latest"
}

variable "artifact_registry_location" {
  type        = string
  description = "Override region for Artifact Registry (defaults to var.region when omitted)."
  default     = null
}

variable "artifact_registry_repository_id" {
  type        = string
  description = "Override repository ID (defaults to <prefix>-services)."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Base labels applied to all resources."
  default     = {}
}

variable "vpc_routing_mode" {
  type        = string
  description = "Routing mode for the shared VPC network."
  default     = "GLOBAL"
}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block assigned to the primary subnet."
  default     = "10.60.2.0/24"
}

variable "default_environment_variables" {
  type        = map(string)
  description = "Environment variables applied to every service unless overridden."
  default     = {}
}

variable "default_secrets" {
  description = "Secret-backed variables applied to all services."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "default_container_concurrency" {
  type        = number
  description = "Fallback concurrency value for Cloud Run services."
  default     = 80
}

variable "service_definitions" {
  description = "Map of service-specific settings used to render Cloud Run services."
  type = map(object({
    repository            = optional(string)
    image                 = optional(string)
    container_port        = optional(number)
    cpu                   = optional(number)
    memory_gb             = optional(number)
    memory                = optional(string)
    env                   = optional(map(string))
    secrets = optional(map(object({
      secret  = string
      version = string
    })))
    ingress = optional(object({
      external_enabled      = optional(bool)
      allow_unauthenticated = optional(bool)
    }))
    min_replicas          = optional(number)
    max_replicas          = optional(number)
    container_concurrency = optional(number)
  }))
}
