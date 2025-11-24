# Terraform Backend Configuration for DEV Environment
# Local Development: Update these values with your actual Azure resources
# CI/CD: These values are overridden by GitHub Environment Secrets

resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstateecodev<unique-id>" # Ejemplo: tfstateecodev1234
container_name       = "tfstate"
key                  = "dev.tfstate"
