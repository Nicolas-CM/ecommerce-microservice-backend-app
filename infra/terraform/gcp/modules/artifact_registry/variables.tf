variable "project_id" {
  type        = string
  description = "GCP project ID hosting the repository."
}

variable "location" {
  type        = string
  description = "Region for the Artifact Registry repository."
}

variable "repository_id" {
  type        = string
  description = "Identifier of the repository (must be unique per location)."
}

variable "description" {
  type        = string
  description = "Optional description for the repository."
  default     = null
}

variable "format" {
  type        = string
  description = "Repository format (DOCKER, MAVEN, NPM, etc)."
  default     = "DOCKER"
}

variable "kms_key_name" {
  type        = string
  description = "Optional Cloud KMS key for encryption."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the repository."
  default     = {}
}
