variable "location" {
  description = "Azure region where the remote state resources are created."
  type        = string
}

variable "resource_group_name" {
  description = "Name for the resource group holding the remote state storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique name for the remote state storage account."
  type        = string
}

variable "container_name" {
  description = "Name of the blob container for Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Common tags applied to the remote state resources."
  type        = map(string)
  default     = {}
}
