variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Region where the Cloud Run service will be deployed."
}

variable "name" {
  type        = string
  description = "Name of the Cloud Run service."
}

variable "image" {
  type        = string
  description = "Container image to deploy."
}

variable "container_port" {
  type        = number
  description = "Exposed container port."
  default     = 8080
}

variable "env" {
  type        = map(string)
  description = "Environment variables injected into the container."
  default     = {}
}

variable "secrets" {
  description = "Map of secret-backed environment variables."
  type = map(object({
    secret = string
    version = string
  }))
  default = {}
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the service."
  default     = {}
}

variable "additional_annotations" {
  type        = map(string)
  description = "Extra annotations merged into the service template."
  default     = {}
}

variable "service_account_email" {
  type        = string
  description = "Service account email used by the service. Leave null to use the default compute service account."
  default     = null
}

variable "container_concurrency" {
  type        = number
  description = "Maximum number of concurrent requests per container."
  default     = 80
}

variable "cpu" {
  type        = string
  description = "CPU limit (e.g. '1', '2')."
  default     = "1"
}

variable "memory" {
  type        = string
  description = "Memory limit (e.g. '512Mi', '2Gi')."
  default     = "512Mi"
}

variable "min_instances" {
  type        = number
  description = "Minimum number of container instances."
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "Maximum number of container instances."
  default     = 5
}

variable "ingress_type" {
  type        = string
  description = "Ingress setting (all, internal, internal-and-cloud-load-balancing)."
  default     = "all"
}

variable "allow_unauthenticated" {
  type        = bool
  description = "Grant public (allUsers) access to the service."
  default     = true
}
