variable "project_id" {
  type        = string
  description = "GCP project ID where the network will be created."
}

variable "name" {
  type        = string
  description = "Name for the VPC network."
}

variable "description" {
  type        = string
  description = "Optional description for the network."
  default     = null
}

variable "routing_mode" {
  type        = string
  description = "Routing mode for the VPC network (GLOBAL or REGIONAL)."
  default     = "GLOBAL"
}

variable "subnets" {
  description = "Map of subnet definitions keyed by an identifier."
  type = map(object({
    name                     = optional(string)
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
}
