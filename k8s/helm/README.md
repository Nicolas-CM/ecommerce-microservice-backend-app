# E-Commerce Microservices - Helm Charts

Este directorio contiene los Helm charts para desplegar los microservicios de E-Commerce en Azure Kubernetes Service (AKS).

## 📁 Estructura

```
k8s/helm/
├── ecommerce-chart/           # Helm chart principal
│   ├── Chart.yaml             # Metadatos del chart
│   ├── values.yaml            # Valores por defecto
│   └── templates/             # Templates de Kubernetes
│       ├── deployments.yaml   # Deployments de microservicios
│       ├── services.yaml      # Services de Kubernetes
│       ├── configmap.yaml     # ConfigMaps
│       └── zipkin.yaml        # Zipkin tracing
├── image-tags.yaml            # ⭐ Configuración de versiones de imágenes
├── deploy.sh                  # Script de despliegue (Linux/Mac)
├── deploy.ps1                 # Script de despliegue (Windows)
└── README.md                  # Este archivo
```

## 🚀 Quick Start

### 1. Configurar Versiones de Imágenes

Edita `image-tags.yaml` con las versiones que deseas desplegar:

```yaml
services:
  api-gateway:
    image: ghcr.io/nicolas-cm/api-gateway
    tag: "0.1.0"  # ← Cambia esto a la versión deseada
```

### 2. Desplegar con Script Automático

**En Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh dev ecommerce
```

**En Windows (PowerShell):**
```powershell
.\deploy.ps1 -Environment dev -Namespace ecommerce
```

### 3. O Desplegar Manualmente

```bash
# Conectar a AKS
az aks get-credentials --resource-group ecommerce-dev-rg --name ecommerce-aks-dev

# Crear secreto de GHCR (primera vez)
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=Nicolas-CM \
  --docker-password=<GITHUB_PAT> \
  --docker-email=tu-email@ejemplo.com \
  --namespace=ecommerce

# Desplegar con Helm
helm upgrade --install ecommerce-microservices ./ecommerce-chart \
  --namespace ecommerce \
  --create-namespace \
  --values ./image-tags.yaml
```

## 📚 Documentación Completa

Para documentación detallada, ver:
- **[HELM-AKS-DEPLOYMENT-GUIDE.md](../../docs/final-part/HELM-AKS-DEPLOYMENT-GUIDE.md)** - Guía completa de despliegue
- **[CI-CD-SETUP-SUMMARY.md](../../docs/final-part/CI-CD-SETUP-SUMMARY.md)** - Resumen de la arquitectura CI/CD

## 🔄 Actualizar un Servicio

```bash
# 1. Editar image-tags.yaml
vim image-tags.yaml

# 2. Cambiar la versión del servicio
# user-service.tag: "0.1.0" → "0.2.0"

# 3. Aplicar cambios
helm upgrade ecommerce-microservices ./ecommerce-chart \
  --namespace ecommerce \
  --values ./image-tags.yaml \
  --reuse-values

# 4. Ver progreso
kubectl rollout status deployment/user-service -n ecommerce
```

## 🛠️ Comandos Útiles

```bash
# Ver estado del despliegue
helm status ecommerce-microservices -n ecommerce

# Ver valores actuales
helm get values ecommerce-microservices -n ecommerce

# Ver todos los pods
kubectl get pods -n ecommerce

# Ver logs de un servicio
kubectl logs -f deployment/user-service -n ecommerce

# Acceder al API Gateway localmente
kubectl port-forward svc/api-gateway 8080:8080 -n ecommerce

# Rollback si hay problemas
helm rollback ecommerce-microservices -n ecommerce
```

## 🎯 Microservicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| api-gateway | 8080 | Gateway principal (LoadBalancer) |
| service-discovery | 8761 | Eureka Server |
| cloud-config | 9296 | Config Server |
| user-service | 8700 | Gestión de usuarios |
| product-service | 8500 | Catálogo de productos |
| order-service | 8300 | Gestión de pedidos |
| payment-service | 8400 | Procesamiento de pagos |
| shipping-service | 8600 | Gestión de envíos |
| favourite-service | 8800 | Favoritos de usuarios |
| proxy-client | 8900 | Cliente proxy |
| zipkin | 9411 | Distributed tracing |

## 🏷️ Tags de Imágenes

Cada servicio tiene múltiples tags disponibles en GHCR:

- `0.1.0` - Versión semántica específica
- `0.1.0-abc1234` - Versión con commit SHA
- `dev-latest` - Última versión de la rama `dev`
- `latest` - Última versión de la rama `main`

**Recomendación**: En producción, usa siempre versiones específicas (e.g., `0.1.0`), nunca `latest`.

## 🔐 Configuración de Secrets

El chart espera un secreto llamado `ghcr-secret` para descargar imágenes de GitHub Container Registry.

Si tus imágenes son **públicas**, puedes comentar esta sección en `ecommerce-chart/values.yaml`:

```yaml
global:
  # imagePullSecrets:
  #   - name: ghcr-secret
```

## 🌍 Ambientes

El chart soporta múltiples ambientes configurados en `values.yaml`:

```yaml
global:
  environment: dev  # dev, staging, production
```

Puedes sobrescribir valores por ambiente creando archivos adicionales:
- `values-dev.yaml`
- `values-staging.yaml`
- `values-production.yaml`

```bash
helm upgrade --install ecommerce-microservices ./ecommerce-chart \
  --namespace ecommerce \
  --values ./ecommerce-chart/values.yaml \
  --values ./image-tags.yaml \
  --values ./values-production.yaml
```

## 📊 Monitoreo

### Eureka Dashboard

```bash
kubectl port-forward svc/service-discovery 8761:8761 -n ecommerce
# Visita: http://localhost:8761
```

### Zipkin Tracing

```bash
kubectl port-forward svc/zipkin 9411:9411 -n ecommerce
# Visita: http://localhost:9411
```

### Health Checks

Todos los microservicios exponen:
- `/actuator/health/liveness` - Liveness probe
- `/actuator/health/readiness` - Readiness probe

## ❓ Troubleshooting

### Pods en ImagePullBackOff

```bash
# Verificar el secreto
kubectl get secret ghcr-secret -n ecommerce

# Recrear el secreto
kubectl delete secret ghcr-secret -n ecommerce
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=Nicolas-CM \
  --docker-password=<NUEVO_PAT> \
  --namespace=ecommerce
```

### Ver logs de errores

```bash
# Logs del pod
kubectl logs <pod-name> -n ecommerce

# Eventos del namespace
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Describir pod
kubectl describe pod <pod-name> -n ecommerce
```

### Servicios no se registran en Eureka

```bash
# Verificar que service-discovery está corriendo
kubectl get pods -n ecommerce -l app=service-discovery

# Ver logs de service-discovery
kubectl logs -n ecommerce -l app=service-discovery

# Reiniciar servicios problemáticos
kubectl rollout restart deployment/user-service -n ecommerce
```

## 📞 Soporte

Para más información, consulta:
- [Documentación de Helm](https://helm.sh/docs/)
- [Documentación de AKS](https://docs.microsoft.com/en-us/azure/aks/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
