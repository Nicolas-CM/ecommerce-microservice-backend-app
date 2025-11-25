# Remote state (GCP)

Terraform configuration to bootstrap the Google Cloud Storage bucket used as the remote state backend for all environments.

## Uso

```pwsh
cd infra/terraform/gcp/remote-state
cp terraform.tfvars.example terraform.tfvars
# Edita los valores (project_id, region, state_bucket_name, etiquetas)
terraform init
terraform apply
```

Esto crea un bucket con:
- Versioning habilitado
- Uniform bucket level access
- Regla de ciclo de vida que elimina versiones antiguas (mantiene 30)

Cuando el bucket existe, cada ambiente (`dev`, `stage`, `prod`) puede apuntar al mismo bucket cambiando únicamente el `prefix` en su `backend.hcl`.
