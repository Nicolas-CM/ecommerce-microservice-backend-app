variable "name" {
  description = "Name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the virtual network is created."
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address spaces assigned to the virtual network."
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create within the virtual network."
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_delegation = optional(object({
      name    = string
      actions = optional(list(string))
    }))
  }))
}

variable "tags" {
  description = "Tags applied to the network resources."
  type        = map(string)
  default     = {}
}
