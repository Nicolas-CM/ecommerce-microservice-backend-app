# NOTE: Este archivo corresponde al backend remoto de Azure.
# Para GCP usa el archivo terraform.tfvars dentro de infra/terraform/gcp/remote-state.

location             = "eastus"
resource_group_name  = "rg-tfstate"
storage_account_name = "stterraformstate"
container_name       = "tfstate"

tags = {
  Project = "ecommerce-microservices"
  Owner   = "platform-team"
}
