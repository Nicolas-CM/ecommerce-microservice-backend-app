variable "namespace" {
  description = "Namespace para el stack de monitoreo"
  type        = string
  default     = "monitoring"
}

variable "prometheus_retention" {
  description = "Periodo de retención de datos de Prometheus"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Tamaño del almacenamiento para Prometheus"
  type        = string
  default     = "20Gi"
}

variable "grafana_admin_password" {
  description = "Contraseña del admin de Grafana"
  type        = string
  sensitive   = true
}

# ELK Stack Variables
variable "elasticsearch_replicas" {
  description = "Número de réplicas de Elasticsearch"
  type        = number
  default     = 1
}

variable "elasticsearch_storage_size" {
  description = "Tamaño del almacenamiento para Elasticsearch"
  type        = string
  default     = "10Gi"
}

variable "elasticsearch_memory" {
  description = "Memoria para Elasticsearch (formato: 512m, 1Gi, etc.)"
  type        = string
  default     = "1Gi"
}

variable "kibana_memory" {
  description = "Memoria para Kibana"
  type        = string
  default     = "1Gi"
}

variable "logstash_replicas" {
  description = "Número de réplicas de Logstash"
  type        = number
  default     = 1
}

variable "logstash_memory" {
  description = "Memoria para Logstash"
  type        = string
  default     = "1Gi"
}

variable "filebeat_memory" {
  description = "Memoria para Filebeat"
  type        = string
  default     = "400Mi"
}
