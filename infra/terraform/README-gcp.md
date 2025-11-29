# Google Cloud Infrastructure Setup

Esta guía documenta los pasos para desplegar la infraestructura del backend de microservicios en Google Cloud Platform (GCP) usando Terraform. El repositorio ya incluye la estructura completa en `infra/terraform/gcp` (módulos, bucket de estado y carpetas por ambiente) equivalente a la implementación previa de Azure.

## 1. Prerrequisitos
- **SDK de Google Cloud (gcloud)** instalado y agregado al `PATH`.
- Un navegador para completar el flujo interactivo de autenticación.
- Acceso a una **cuenta de facturación** activa en GCP.
- Terraform ≥ 1.7 instalado localmente.

## 2. Autenticación inicial
```pwsh
# Inicia la configuración del SDK
gcloud init

# Habilita las credenciales por defecto que consumirá Terraform
gcloud auth application-default login

# Alinea el proyecto de cuota para evitar advertencias de uso
gcloud auth application-default set-quota-project eco-microservices-dev
```

## 3. Crear o seleccionar un proyecto
```pwsh
# Ver los proyectos disponibles
gcloud projects list

# Crear un proyecto nuevo (ID único, 6-30 caracteres)
gcloud projects create eco-microservices-dev --name="Ecommerce Microservices Dev"

# (Opcional) definir el proyecto actual
gcloud config set project eco-microservices-dev
```
> **Nota:** si necesitas otro entorno (stage/prod) repite el comando con IDs diferentes.

## 4. Vincular facturación
```pwsh
# Listar cuentas de facturación disponibles
gcloud beta billing accounts list

# Enlazar la cuenta al proyecto
gcloud beta billing projects link eco-microservices-dev --billing-account=<BILLING_ACCOUNT_ID>
```

## 5. Habilitar APIs necesarias
```pwsh
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com
```

Refuerza la configuración local del CLI (requerido por Terraform cuando falten flags explícitos):
```pwsh
gcloud config set project eco-microservices-dev
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## 6. Etiquetas (opcional)
El comando `gcloud resource-manager tags bindings create` requiere **dos parámetros obligatorios**:
- `--parent`: recurso al que se aplica (p. ej. `projects/eco-microservices-dev`).
- `--tag-value`: identificador completo del valor del tag (formato `tagValues/123456789012`).

Pasos para crear y usar un tag `environment=development`:
```pwsh
# (Solo si todavía no existen) crear la clave de tag a nivel de organización
# Reemplaza <ORG_ID> con tu ID de organización; si no tienes organización, omite esta sección
#gcloud resource-manager tags keys create environment --parent=organizations/<ORG_ID> --location=global

# Crear el valor "development" asociado a la clave anterior
#gcloud resource-manager tags values create development --parent=tagKeys/KEY_ID --location=global

# Vincular el tag al proyecto
#gcloud resource-manager tags bindings create \
#  --parent=projects/eco-microservices-dev \
#  --tag-value=tagValues/VALUE_ID
```
Si trabajas sin organización, puedes usar **labels** en lugar de tags:
```pwsh
gcloud projects update eco-microservices-dev --update-labels=environment=development
```

## 7. Backend remoto para Terraform
El bucket y la configuración del backend están descritos en `infra/terraform/gcp/remote-state`:

```pwsh
cd infra/terraform/gcp/remote-state
cp terraform.tfvars.example terraform.tfvars   # ajusta project_id, region, state_bucket_name si lo necesitas
terraform init
terraform apply
```

> ✅ `terraform init` ya se ejecutó correctamente en esta carpeta y fijó el proveedor `hashicorp/google` en `.terraform.lock.hcl`. Si cambias versiones o variables, vuelve a correr `terraform init` antes del próximo `plan`/`apply`.

Características del bucket generado:
- Versioning habilitado y regla de lifecycle que conserva las últimas 30 versiones del estado.
- Acceso uniforme a nivel de bucket (`uniform_bucket_level_access = true`).
- Soporte opcional para cifrado con CMEK (`kms_key_name`).

Cada ambiente incluye un `backend.hcl` que apunta al mismo bucket con prefijos distintos (`gcp/dev`, `gcp/stage`, `gcp/prod`).

## 8. Layout actual en `infra/terraform/gcp`

- `modules/network`: crea una VPC personalizada (sin subredes automáticas) y subredes parametrizables por región y CIDR.
- `modules/artifact_registry`: aprovisiona un repositorio Docker regional y expone el endpoint `<region>-docker.pkg.dev/<project>/<repo>` para los builds.
- `modules/cloud_run_service`: renderiza servicios de Cloud Run con ajustes de CPU/memoria, escalado min/max, `ingress` público o privado y soporte para variables/secrets (Secret Manager).
- `remote-state`: bootstrap del bucket GCS + tfvars de ejemplo.
- `environments/dev`: ambiente completamente configurado para `eco-microservices-dev` (us-central1) con los nueve microservicios definidos en `service_definitions`.
- `environments/stage` y `environments/prod`: misma estructura que `dev`, cada uno con `backend.hcl` listo y `terraform.tfvars.example` para copiar cuando crees los proyectos correspondientes.

> `default_secrets` y cada `service_definitions["nombre"].secrets` esperan objetos `{ secret = "mi-secreto", version = "latest" }` apuntando a Secret Manager. Si aún no gestionas secretos en GCP, deja esos mapas vacíos y confía solo en `default_environment_variables`.

## 9. Flujo de despliegue
```pwsh
# 1) Backend remoto (una sola vez)
cd infra/terraform/gcp/remote-state
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# 2) Ambiente dev (ya trae terraform.tfvars con project_id=eco-microservices-dev)
cd ../environments/dev
terraform init -backend-config=backend.hcl
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# 3) Stage / Prod (cuando existan los proyectos)
cd ../stage
cp terraform.tfvars.example terraform.tfvars   # actualiza project_id, región, etiquetas, CIDR
terraform init -backend-config=backend.hcl
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## 10. Próximos pasos
1. Ejecutar `terraform apply` dentro de `remote-state` para crear el bucket (si aún no existe).
2. (Opcional) Crear secretos en Secret Manager y rellenar `default_secrets` + `service_definitions[*].secrets`.
3. Replicar el flujo `dev` en `stage/prod` creando los proyectos GCP respectivos y copiando los `.tfvars.example`.
4. Automatizar el push de imágenes hacia Artifact Registry (`<region>-docker.pkg.dev/eco-microservices-*/<repo>`) desde el pipeline de CI/CD.

Con esto la infraestructura GCP queda lista para iterar y desplegar los microservicios vía Terraform.
