variable "project_id" {
  type        = string
  description = "ID del proyecto donde se creará el bucket remoto de Terraform."
}

variable "region" {
  type        = string
  description = "Región de Google Cloud usada para el bucket de estado."
}

variable "state_bucket_name" {
  type        = string
  description = "Nombre único (global) del bucket de Google Cloud Storage para el estado."
}

variable "storage_class" {
  type        = string
  description = "Clase de almacenamiento a utilizar para el bucket de estado."
  default     = "STANDARD"
}

variable "force_destroy" {
  type        = bool
  description = "Permite eliminar el bucket aunque existan objetos. Úsalo solo en entornos de desarrollo."
  default     = false
}

variable "kms_key_name" {
  type        = string
  description = "ARN completo de la clave CMEK usada para cifrado. Deja vacío para usar claves predeterminadas de Google."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Etiquetas que se aplicarán al bucket."
  default     = {}
}
