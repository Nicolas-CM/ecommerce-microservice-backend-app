variable "load_balancer_ip" {
  description = "IP pública estática para el Load Balancer (dejar vacío para IP dinámica)"
  type        = string
  default     = ""
}

variable "static_ip_resource_group" {
  description = "Resource group donde está la IP estática"
  type        = string
  default     = ""
}
