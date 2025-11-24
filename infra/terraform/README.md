# Infraestructura en Azure con Terraform

Esta carpeta define toda la infraestructura necesaria para desplegar los microservicios de la plataforma en Azure utilizando una arquitectura modular. La solución contempla tres ambientes (`dev`, `stage`, `prod`) y soporta un backend remoto en Azure Storage para mantener el estado de Terraform.

## 🏗️ Arquitectura

La infraestructura está diseñada para soportar:
- **Azure Kubernetes Service (AKS)**: Orquestación de contenedores para microservicios
- **Azure Container Apps (ACA)**: Alternativa serverless para microservicios
- **Azure Container Registry (ACR)**: Registro privado de imágenes Docker
- **Virtual Network**: Red privada con subnets dedicadas

## Estructura

```
infra/terraform
├── modules/                  # Módulos reutilizables
│   ├── aks/                 # Azure Kubernetes Service (NUEVO)
│   ├── acr/                 # Azure Container Registry
│   ├── network/             # Virtual Network y Subnets
│   ├── log_analytics/       # Log Analytics Workspace
│   ├── resource_group/      # Resource Group
│   ├── container_apps_env/  # Container Apps Environment
│   └── container_app/       # Container App individual
├── remote-state/            # Stack para crear storage account del backend
└── environments/
    ├── dev/                 # ✅ CONFIGURADO CON AKS
    │   ├── main.tf          # Configuración principal con AKS
    │   ├── variables.tf     # Variables incluyendo AKS
    │   ├── outputs.tf       # Outputs de AKS y otros recursos
    │   ├── terraform.tfvars # Valores para ambiente DEV
    │   └── backend.hcl      # Configuración del backend
    ├── stage/               # Ambiente de staging (próximamente)
    └── prod/                # Ambiente de producción (próximamente)
```

### Módulos disponibles
- **`resource_group`**: Administra grupos de recursos Azure
- **`network`**: Crea VNet con subnets para AKS y Container Apps
- **`log_analytics`**: Workspace para diagnósticos y métricas
- **`acr`**: Azure Container Registry para las imágenes
- **`aks`**: 🆕 Azure Kubernetes Service con auto-scaling y monitoreo
- **`container_apps_env`**: Entorno de Azure Container Apps
- **`container_app`**: Definición parametrizable por microservicio

## Prerrequisitos
1. Terraform >= 1.7.0.
2. Azure CLI autenticado (`az login`).
3. Permisos para crear recursos en la suscripción destino.

## 1. Aprovisionar el backend remoto
1. Entrar en `infra/terraform/remote-state` y crear un archivo `terraform.tfvars` (usar como guía las variables del módulo):
   ```hcl
   location             = "eastus"
   resource_group_name  = "rg-terraform-state"
   storage_account_name = "stterraformstate123"
   container_name       = "tfstate"
   tags = {
     Project = "ecommerce-microservices"
   }
   ```
2. Ejecutar Terraform localmente:
   ```pwsh
   cd infra/terraform/remote-state
   terraform init
   terraform apply
   ```
3. Anota el nombre del resource group, storage account y contenedor; se usarán en los ambientes.

## 2. Configurar cada ambiente
Cada carpeta (`dev`, `stage`, `prod`) contiene:
- `backend.tf`: declaración del backend `azurerm`.
- `backend.hcl.example`: valores esperados para `terraform init -backend-config=backend.hcl`.
- `terraform.tfvars.example`: plantilla de variables de entrada por ambiente.
- Archivos `.tf` comunes (`main`, `variables`, `outputs`, `versions`).

### Pasos
1. Copiar los archivos de ejemplo:
   ```pwsh
   cd infra/terraform/environments/dev
   Copy-Item backend.hcl.example backend.hcl
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```
2. Editar `backend.hcl` con los datos reales del storage account creado en el paso anterior.
3. Editar `terraform.tfvars` con:
   - `subscription_id` y `tenant_id` reales.
   - `location`, `global_prefix`, `image_tag` deseados.
   - Definición detallada por microservicio (`service_definitions`). Cada entrada permite ajustar `repository`, `image`, `container_port`, `cpu`, `memory_gb`, reglas de ingress, variables/secrets específicos y mínimos/máximos de réplicas.
4. Inicializar y desplegar:
   ```pwsh
   terraform init -backend-config=backend.hcl
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

> **Tip:** Mantén las imágenes de cada servicio en el ACR generado (`acr_login_server` en los outputs). El módulo asume que la etiqueta configurada en `image_tag` existe para cada repositorio.

## Variables y convenciones clave
- `global_prefix`: prefijo corto usado en el nombre de todos los recursos (p. ej. `eco`).
- `environment_name`: uno de `dev`, `stage`, `prod`. Se utiliza para etiquetar recursos y construir nombres únicos (`eco-dev`, `eco-prod`, ...).
- `service_definitions`: mapa donde la clave es el nombre lógico del microservicio y el valor describe su despliegue. Campos disponibles:
  ```hcl
  service_definitions = {
    api-gateway = {
      repository     = "api-gateway"   # opcional si coincide con la clave
      image          = "custom.registry/api-gateway:tag" # opcional, sobreescribe repository+tag
      container_port = 8080
      cpu            = 0.5              # opcional, default 0.5
      memory_gb      = 1                # opcional, default 1
      ingress = {
        external_enabled = true
        target_port      = 8080
        transport        = "auto"
        allow_insecure_connections = false
      }
      env = {
        SPRING_PROFILES_ACTIVE = "dev"
      }
      secrets = {
        DB_PASSWORD = "kv://secret"
      }
      min_replicas = 1
      max_replicas = 3
    }
  }
  ```
- `default_environment_variables` / `default_secrets`: se aplican a todos los servicios y se mezclan con los específicos.

## Cómo extender la infraestructura
- **Nuevos servicios:** añade una entrada en `service_definitions`. Al aplicar, Terraform creará un nuevo `azurerm_container_app` usando el módulo `container_app`.
- **Más ambientes:** duplica una carpeta dentro de `environments/` y actualiza `environment_name`, `backend.hcl` y `terraform.tfvars`.
- **Networking avanzada:** el módulo `network` acepta más subredes; amplía el mapa `subnets` dentro de `main.tf` según tus necesidades.

## Limpieza
Para destruir un ambiente completo:
```pwsh
cd infra/terraform/environments/dev
terraform destroy -var-file=terraform.tfvars
```
(El backend remoto suele mantenerse para preservar historiales de estado.)
