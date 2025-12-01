[🏠 Volver al README](../../README.md#documentación-de-infraestructura-como-código)

---

# Infrastructure as Code Documentation
## Documentación de Infraestructura como Código

> **Proyecto**: E-commerce Microservices Backend  
> **Versión**: 1.0  
> **Fecha**: Diciembre 2025  
> **Herramientas**: Kubernetes, Helm, Docker

---

## 📋 Índice

1. [Introducción](#introducción)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Docker - Containerización](#docker---containerización)
4. [Kubernetes Manifests](#kubernetes-manifests)
5. [Helm Charts](#helm-charts)
6. [Gestión de Configuración](#gestión-de-configuración)
7. [Namespaces y Ambientes](#namespaces-y-ambientes)
8. [Networking y Service Mesh](#networking-y-service-mesh)
9. [Persistencia y Almacenamiento](#persistencia-y-almacenamiento)
10. [Seguridad](#seguridad)
11. [Monitoreo e Instrumentación](#monitoreo-e-instrumentación)
12. [Buenas Prácticas](#buenas-prácticas)

---

## 🎯 Introducción

Este documento describe la infraestructura del proyecto de microservicios de e-commerce, implementada siguiendo principios de **Infrastructure as Code (IaC)**. Todo está versionado en Git, permitiendo reproducibilidad, auditabilidad y gestión de cambios.

### Principios de IaC Aplicados

1. **Declarativo sobre Imperativo**: Definimos el estado deseado, no los pasos para alcanzarlo
2. **Versionado**: Toda la infraestructura está en Git con historial completo
3. **Inmutabilidad**: No modificamos recursos corriendo; desplegamos nuevas versiones
4. **Idempotencia**: Aplicar la misma configuración múltiples veces produce el mismo resultado
5. **Automatización**: Deploys via CI/CD, sin pasos manuales
6. **Documentación como Código**: Esta documentación vive junto al código

### Stack Tecnológico

```yaml
Containerización: Docker (multi-arch: amd64, arm64)
Orquestación: Kubernetes 1.28+
Gestión de Paquetes: Helm 3.12+
Registro de Imágenes: GitHub Container Registry (GHCR)
Plataforma Cloud: Azure Kubernetes Service (AKS)
CI/CD: GitHub Actions
```

---

## 📂 Estructura del Proyecto

```
ecommerce-microservice-backend-app/
├── compose.yml                          # Docker Compose (desarrollo local)
├── pom.xml                              # Maven parent POM
│
├── [microservice]/                      # 10 microservicios
│   ├── Dockerfile                       # Containerización
│   ├── pom.xml                          # Dependencias Maven
│   └── src/                             # Código fuente
│
├── k8s/                                 # Kubernetes manifests
│   ├── base/                            # Configuraciones base (sin Helm)
│   │   ├── namespace.yaml
│   │   ├── config/
│   │   │   ├── configmap.yaml
│   │   │   └── secrets.yaml
│   │   └── services/
│   │       ├── user-service-deployment.yaml
│   │       ├── user-service-service.yaml
│   │       └── ...
│   │
│   └── helm/                            # Helm Charts (PRODUCCIÓN)
│       ├── ecommerce-chart/             # Chart principal
│       │   ├── Chart.yaml               # Metadata del chart
│       │   ├── values.yaml              # Valores por defecto
│       │   ├── templates/               # Templates de Kubernetes
│       │   │   ├── deployment.yaml
│       │   │   ├── service.yaml
│       │   │   ├── ingress.yaml
│       │   │   ├── configmap.yaml
│       │   │   ├── secrets.yaml
│       │   │   ├── hpa.yaml
│       │   │   └── _helpers.tpl        # Funciones de template
│       │   └── ...
│       │
│       ├── values-dev.yaml              # Override para dev
│       ├── values-stage.yaml            # Override para stage
│       ├── values-prod.yaml             # Override para producción
│       └── image-tags-prod.yaml         # Tags de imágenes (prod)
│
├── scripts/                             # Scripts de automatización
│   ├── build-all-images.sh
│   ├── deploy-dev.sh
│   ├── deploy-stage.sh
│   └── health-check.sh
│
└── .github/workflows/                   # Pipelines CI/CD
    ├── ci-cd-dev.yml
    ├── ci-cd-stage.yml
    ├── ci-cd-prod.yml
    └── security-scan.yml
```

---

## 🐳 Docker - Containerización

### Estrategia de Containerización

Todos los microservicios siguen el mismo patrón de Dockerfile multi-stage para optimizar tamaño y seguridad.

### Dockerfile Estándar

**Ubicación**: `<microservice>/Dockerfile`

```dockerfile
# Stage 1: Build
FROM maven:3.9.5-eclipse-temurin-17 AS build
WORKDIR /app

# Copiar solo pom.xml primero (mejor caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime (multi-arch)
FROM eclipse-temurin:17-jre
WORKDIR /app

# Crear usuario no-root para seguridad
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copiar JAR desde build stage
COPY --from=build /app/target/*.jar app.jar

# Cambiar ownership
RUN chown -R appuser:appuser /app
USER appuser

# Exponer puerto
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Ejecutar aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Build Multi-Arquitectura

Soportamos **linux/amd64** y **linux/arm64** para compatibilidad con diferentes tipos de nodos en AKS.

```bash
# Build y push para múltiples arquitecturas
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi \
  --push \
  ./user-service/

# Verificar manifest multi-arch
docker buildx imagetools inspect ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi
```

**Output esperado**:
```
Name:      ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:abc123...

Manifests:
  Name:      ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi@sha256:def456...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64

  Name:      ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi@sha256:ghi789...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64
```

### Convenciones de Tags

```
Desarrollo:
  - dev                      # Último build de branch dev
  - dev-<commit-sha>         # Build específico

Stage:
  - stage                    # Release candidate
  - stage-<version>          # RC con versión (e.g., stage-0.1.0)

Producción:
  - latest                   # Última versión estable
  - <version>-prod-multi     # Versión productiva multi-arch (e.g., 0.1.0-prod-multi)
  - <version>                # Versión específica (e.g., 0.1.0)
```

### Optimizaciones de Dockerfile

**Reducir tamaño de imagen**:
```dockerfile
# Malo: Imagen grande con Maven
FROM maven:3.9.5-eclipse-temurin-17
COPY . .
RUN mvn clean package
ENTRYPOINT ["java", "-jar", "target/app.jar"]

# Bueno: Multi-stage, solo JRE en runtime
FROM maven:3.9.5-eclipse-temurin-17 AS build
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre
COPY --from=build /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Tamaño de imágenes**:
```
maven:3.9.5-eclipse-temurin-17:  680 MB
eclipse-temurin:17-jre:          285 MB  ✅ (usamos este)
eclipse-temurin:17-jre-alpine:   180 MB  (no soporta arm64)
```

---

## ☸️ Kubernetes Manifests

### Namespace

Define aislamiento lógico para cada ambiente.

**Archivo**: `k8s/base/namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
    app.kubernetes.io/managed-by: helm
---
apiVersion: v1
kind: Namespace
metadata:
  name: stage
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
```

### Deployment

Define cómo se despliegan los pods de cada microservicio.

**Archivo**: `k8s/base/services/user-service-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: prod
  labels:
    app: user-service
    app.kubernetes.io/component: microservice
    app.kubernetes.io/part-of: ecommerce
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 1
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      containers:
      - name: user-service
        image: ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: EUREKA_SERVER_URL
          valueFrom:
            configMapKeyRef:
              name: ecommerce-config
              key: EUREKA_SERVER_URL
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
```

**Explicación de Campos Clave**:

- **replicas**: Número de pods corriendo simultáneamente (alta disponibilidad)
- **strategy.RollingUpdate**: Deploy gradual sin downtime
  - `maxUnavailable: 25%`: Máximo 25% de pods pueden estar down durante update
  - `maxSurge: 1`: Máximo 1 pod extra durante update
- **resources**: Límites de CPU/memoria
  - `requests`: Recursos garantizados (usado por scheduler)
  - `limits`: Recursos máximos permitidos (pod killed si excede)
- **livenessProbe**: ¿El pod está vivo? Si falla, Kubernetes lo reinicia
- **readinessProbe**: ¿El pod puede recibir tráfico? Si falla, se quita del Service

### Service

Expone el Deployment como servicio de red accesible.

**Archivo**: `k8s/base/services/user-service-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: prod
  labels:
    app: user-service
spec:
  type: ClusterIP
  selector:
    app: user-service
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 8080
  sessionAffinity: None
```

**Tipos de Service**:
- **ClusterIP** (default): IP interna del cluster, accesible solo dentro de Kubernetes
- **NodePort**: Expone en puerto de cada nodo (30000-32767)
- **LoadBalancer**: Crea balanceador externo (Azure Load Balancer)

### Ingress

Maneja tráfico HTTP(S) externo hacia los servicios.

**Archivo**: `k8s/base/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: prod
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - cuellarapp.online
    - www.cuellarapp.online
    secretName: ecommerce-tls
  rules:
  - host: cuellarapp.online
    http:
      paths:
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
      - path: /api/products
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 8080
      - path: /api/orders
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

**Características**:
- Enrutamiento basado en path (`/api/users` → user-service)
- TLS/SSL automático con cert-manager
- Redirect HTTP → HTTPS

---

## 🎡 Helm Charts

Helm es un **gestor de paquetes para Kubernetes**, facilitando despliegues complejos con parametrización y versionado.

### Estructura del Chart

```
k8s/helm/ecommerce-chart/
├── Chart.yaml              # Metadata del chart
├── values.yaml             # Valores por defecto
├── templates/              # Templates de Kubernetes
│   ├── deployment.yaml     # Deployment para cada servicio
│   ├── service.yaml        # Service para cada servicio
│   ├── ingress.yaml        # Ingress compartido
│   ├── configmap.yaml      # ConfigMap
│   ├── secrets.yaml        # Secrets
│   ├── hpa.yaml            # HorizontalPodAutoscaler
│   ├── _helpers.tpl        # Funciones helper
│   └── NOTES.txt           # Mensaje post-install
└── charts/                 # Subcharts (dependencias)
```

### Chart.yaml

Define metadata del chart.

```yaml
apiVersion: v2
name: ecommerce-chart
description: Helm chart for E-commerce Microservices
type: application
version: 0.1.0
appVersion: "2025.12.01"
keywords:
  - ecommerce
  - microservices
  - spring-boot
maintainers:
  - name: DevOps Team
    email: devops@company.com
```

### values.yaml

Valores configurables (pueden ser sobreescritos con `-f values-prod.yaml`).

```yaml
# Valores globales
global:
  environment: prod
  domain: cuellarapp.online

# Configuración de imágenes (sobreescrito por image-tags-prod.yaml)
imageTags:
  cloudConfig: "0.1.0-prod-multi"
  serviceDiscovery: "0.1.0-prod-multi"
  apiGateway: "0.1.0-prod-multi"
  productService: "0.1.0-prod-multi"
  orderService: "0.1.0-prod-multi"
  userService: "0.1.0-prod-multi"
  paymentService: "0.1.0-prod-multi"
  shippingService: "0.1.0-prod-multi"
  favouriteService: "0.1.0-prod-multi"
  proxyClient: "0.1.0-prod-multi"

# Configuración por servicio
userService:
  enabled: true
  replicaCount: 3
  image:
    repository: ghcr.io/nicolas-cm/user-service
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 8080
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

productService:
  enabled: true
  replicaCount: 3
  # ... (similar a userService)

# ... (resto de servicios)

# Ingress
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: cuellarapp.online
      paths:
        - path: /
          pathType: Prefix
          backend: api-gateway
  tls:
    - secretName: ecommerce-tls
      hosts:
        - cuellarapp.online

# ConfigMap (variables de ambiente no sensibles)
config:
  SPRING_PROFILES_ACTIVE: "prod"
  EUREKA_SERVER_URL: "http://service-discovery:8761/eureka"
  LOGGING_LEVEL: "INFO"

# Secrets (se debe crear manualmente antes de deploy)
secrets:
  DB_USERNAME: "postgres"
  DB_PASSWORD: "<encrypted>"
```

### Templates con Go Templating

Helm usa **Go templates** para generar manifiestos dinámicamente.

**Ejemplo**: `templates/deployment.yaml`

```yaml
{{- range $serviceName, $serviceConfig := .Values }}
{{- if and (kindIs "map" $serviceConfig) (hasKey $serviceConfig "enabled") $serviceConfig.enabled }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $serviceName }}
  namespace: {{ $.Release.Namespace }}
  labels:
    app: {{ $serviceName }}
    {{- include "ecommerce-chart.labels" $ | nindent 4 }}
spec:
  replicas: {{ $serviceConfig.replicaCount | default 2 }}
  selector:
    matchLabels:
      app: {{ $serviceName }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 1
  template:
    metadata:
      labels:
        app: {{ $serviceName }}
    spec:
      containers:
      - name: {{ $serviceName }}
        image: "{{ $serviceConfig.image.repository }}:{{ index $.Values.imageTags (include "ecommerce-chart.camelCase" $serviceName) }}"
        imagePullPolicy: {{ $serviceConfig.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ $serviceConfig.service.port }}
        env:
        {{- range $key, $value := $.Values.config }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        resources:
          {{- toYaml $serviceConfig.resources | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: {{ $serviceConfig.service.port }}
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: {{ $serviceConfig.service.port }}
          initialDelaySeconds: 30
          periodSeconds: 5
{{- end }}
{{- end }}
```

**Funciones de Template Útiles**:
- `{{ .Values.userService.replicaCount }}`: Accede a valor
- `{{ default 2 .Values.replicaCount }}`: Valor por defecto
- `{{ include "helper" . }}`: Incluye template helper
- `{{ range ... }}`: Loop sobre lista/map
- `{{ if ... }}`: Condicional
- `{{ toYaml .Values.resources | nindent 4 }}`: Convierte a YAML con indentación

### Helpers (_helpers.tpl)

Funciones reutilizables.

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "ecommerce-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ecommerce-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ecommerce-chart.labels" -}}
helm.sh/chart: {{ include "ecommerce-chart.name" . }}
{{ include "ecommerce-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: ecommerce
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ecommerce-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecommerce-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Convert service name to camelCase for imageTags lookup
user-service -> userService
*/}}
{{- define "ecommerce-chart.camelCase" -}}
{{- $parts := splitList "-" . }}
{{- $first := index $parts 0 }}
{{- $rest := slice $parts 1 }}
{{- $camelRest := list }}
{{- range $rest }}
  {{- $camelRest = append $camelRest (title .) }}
{{- end }}
{{- printf "%s%s" $first (join "" $camelRest) }}
{{- end }}
```

### Despliegue con Helm

```bash
# Instalar chart (primera vez)
helm install ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./k8s/helm/values-prod.yaml \
  -f ./k8s/helm/image-tags-prod.yaml \
  -n prod \
  --create-namespace

# Upgrade (actualizar)
helm upgrade ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./k8s/helm/values-prod.yaml \
  -f ./k8s/helm/image-tags-prod.yaml \
  -n prod

# Install or Upgrade (idempotente)
helm upgrade --install ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./k8s/helm/values-prod.yaml \
  -f ./k8s/helm/image-tags-prod.yaml \
  -n prod

# Ver valores calculados (debug)
helm get values ecommerce-app -n prod

# Ver manifests generados (sin aplicar)
helm template ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./k8s/helm/values-prod.yaml \
  -f ./k8s/helm/image-tags-prod.yaml

# Rollback a versión anterior
helm rollback ecommerce-app -n prod

# Ver historial de releases
helm history ecommerce-app -n prod
```

---

## ⚙️ Gestión de Configuración

### ConfigMaps

Almacenan configuración **no sensible** como variables de ambiente.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ecommerce-config
  namespace: prod
data:
  SPRING_PROFILES_ACTIVE: "prod"
  EUREKA_SERVER_URL: "http://service-discovery:8761/eureka"
  LOGGING_LEVEL: "INFO"
  DB_POOL_SIZE: "30"
  REDIS_HOST: "ecommerce-redis.redis.cache.windows.net"
  REDIS_PORT: "6380"
  KAFKA_BOOTSTRAP_SERVERS: "ecommerce-kafka:9092"
```

**Uso en Deployment**:
```yaml
env:
- name: EUREKA_SERVER_URL
  valueFrom:
    configMapKeyRef:
      name: ecommerce-config
      key: EUREKA_SERVER_URL
```

### Secrets

Almacenan información **sensible** (contraseñas, tokens, certificados).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: prod
type: Opaque
data:
  username: cG9zdGdyZXM=  # base64("postgres")
  password: c3VwZXJzZWNyZXRwYXNzd29yZA==  # base64("supersecretpassword")
```

**Crear Secret desde comando**:
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=supersecretpassword \
  -n prod
```

**Uso en Deployment**:
```yaml
env:
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: password
```

### Azure Key Vault (Recomendado para Producción)

Para mayor seguridad, integrar con Azure Key Vault usando **AAD Pod Identity** o **Workload Identity**.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: prod
type: Opaque
stringData:
  username: postgres
  password: "${KEY_VAULT_SECRET:db-password}"  # Placeholder
```

**Azure Key Vault Provider for Secrets Store CSI Driver**:
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault
  namespace: prod
spec:
  provider: azure
  parameters:
    keyvaultName: "ecommerce-keyvault"
    tenantId: "<tenant-id>"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
```

---

## 🌐 Namespaces y Ambientes

### Estrategia de Namespaces

Separación lógica de ambientes en el mismo cluster.

```yaml
prod:       # Producción (usuarios reales)
stage:      # Pre-producción (testing final)
dev:        # Desarrollo (testing continuo)
monitoring: # Prometheus, Grafana, Zipkin
```

**Ventajas**:
- Aislamiento de recursos
- Políticas de RBAC por namespace
- Resource Quotas diferentes por ambiente
- Network Policies para seguridad

### Resource Quotas

Limitar recursos por namespace para evitar que dev/stage consuman recursos de prod.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "50"
```

### LimitRange

Establecer límites default para pods sin recursos especificados.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: dev
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "250m"
      memory: "256Mi"
    type: Container
```

---

## 🔌 Networking y Service Mesh

### Service Discovery con Eureka

Los microservicios se registran automáticamente en Eureka Server para descubrirse mutuamente.

**Configuración en application.yml**:
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: ${EUREKA_SERVER_URL:http://service-discovery:8761/eureka}
  instance:
    preferIpAddress: true
    leaseRenewalIntervalInSeconds: 10
```

**Pod de Eureka Server**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-discovery
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: service-discovery
        image: ghcr.io/nicolas-cm/service-discovery:0.1.0-prod-multi
        ports:
        - containerPort: 8761
```

### API Gateway con Spring Cloud Gateway

Punto de entrada único que enruta requests a microservicios.

**Flujo de Request**:
```
User Request → Azure Load Balancer → Ingress → API Gateway → Microservicio
```

**Configuración de Routing**:
```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: user-service
        uri: lb://USER-SERVICE  # Load balance via Eureka
        predicates:
        - Path=/api/users/**
        filters:
        - StripPrefix=1
      
      - id: product-service
        uri: lb://PRODUCT-SERVICE
        predicates:
        - Path=/api/products/**
        filters:
        - StripPrefix=1
```

### Network Policies (Seguridad)

Controlar tráfico de red entre pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-gateway-to-services
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: microservice
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8080
```

**Explicación**: Solo el API Gateway puede comunicarse con los microservicios. Bloques acceso directo externo.

---

## 💾 Persistencia y Almacenamiento

### Azure Database for PostgreSQL

Base de datos externa al cluster (managed service).

**Connection String almacenado en Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  connection-string: "postgresql://adminuser:password@ecommerce-db-prod.postgres.database.azure.com:5432/ecommerce?sslmode=require"
```

**Uso en Deployment**:
```yaml
env:
- name: SPRING_DATASOURCE_URL
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: connection-string
```

### Persistent Volume Claims (PVC)

Para almacenamiento persistente dentro del cluster (logs, uploads, etc.).

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logs-pvc
  namespace: prod
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  resources:
    requests:
      storage: 10Gi
```

**Montar en Pod**:
```yaml
spec:
  volumes:
  - name: logs-volume
    persistentVolumeClaim:
      claimName: logs-pvc
  containers:
  - name: user-service
    volumeMounts:
    - name: logs-volume
      mountPath: /app/logs
```

---

## 🔐 Seguridad

### RBAC (Role-Based Access Control)

Controlar quién puede hacer qué en el cluster.

**ServiceAccount**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecommerce-app
  namespace: prod
```

**Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: prod
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

**RoleBinding**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: prod
subjects:
- kind: ServiceAccount
  name: ecommerce-app
  namespace: prod
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Pod Security Standards

Aplicar políticas de seguridad a nivel de namespace.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Políticas**:
- **Privileged**: Sin restricciones (solo para system namespaces)
- **Baseline**: Previene escalación de privilegios conocidas
- **Restricted**: Máxima seguridad (recomendado para prod)

### Secrets Encryption at Rest

Asegurar que secrets en etcd estén encriptados.

**Azure AKS habilita esto por defecto**, pero verificar:
```bash
az aks show \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --query "diskEncryptionSetId"
```

---

## 📊 Monitoreo e Instrumentación

### Prometheus

Scraping de métricas de todos los microservicios.

**ServiceMonitor** (si se usa Prometheus Operator):
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ecommerce-services
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: microservice
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

**Métricas expuestas por Spring Boot Actuator**:
```
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{area="heap",id="PS Eden Space",} 1.048576E8

# HELP http_server_requests_seconds  
# TYPE http_server_requests_seconds summary
http_server_requests_seconds_count{method="GET",status="200",uri="/api/users",} 1523.0
http_server_requests_seconds_sum{method="GET",status="200",uri="/api/users",} 78.456
```

### Grafana Dashboards

Visualización de métricas.

**Dashboard JSON** almacenado en Git:
```json
{
  "dashboard": {
    "title": "Ecommerce - API Overview",
    "panels": [
      {
        "title": "Request Rate (RPS)",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_total[5m])) by (service)"
          }
        ]
      },
      {
        "title": "Error Rate (%)",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_total{status=~\"5..\"}[5m])) by (service) / sum(rate(http_server_requests_total[5m])) by (service) * 100"
          }
        ]
      }
    ]
  }
}
```

### Distributed Tracing (Zipkin)

Rastreo de requests a través de múltiples microservicios.

**Configuración en application.yml**:
```yaml
spring:
  zipkin:
    base-url: http://zipkin:9411
  sleuth:
    sampler:
      probability: 1.0  # 100% de traces en stage/dev, 0.1 (10%) en prod
```

**Deployment de Zipkin**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: monitoring
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin:latest
        ports:
        - containerPort: 9411
```

---

## ✅ Buenas Prácticas

### 1. Inmutabilidad de Imágenes

**✅ HACER**:
```yaml
image: ghcr.io/nicolas-cm/user-service:0.1.0-prod-multi
imagePullPolicy: IfNotPresent
```

**❌ EVITAR**:
```yaml
image: ghcr.io/nicolas-cm/user-service:latest  # Mutable, no reproducible
imagePullPolicy: Always  # Siempre pull, más lento
```

### 2. Resource Limits

**✅ HACER**: Siempre especificar requests y limits
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

**❌ EVITAR**: Sin límites (pod puede consumir todos los recursos del nodo)

### 3. Health Checks

**✅ HACER**: Implementar ambos probes
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
```

**❌ EVITAR**: Sin health checks (Kubernetes no sabe si pod está sano)

### 4. Rolling Updates

**✅ HACER**:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 1
```

**❌ EVITAR**:
```yaml
strategy:
  type: Recreate  # Downtime durante deploy
```

### 5. Configuración Externalizada

**✅ HACER**: ConfigMaps y Secrets
```yaml
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: ecommerce-config
      key: DB_HOST
```

**❌ EVITAR**: Hardcoded en Dockerfile
```dockerfile
ENV DB_HOST=ecommerce-db-prod.postgres.database.azure.com
```

### 6. Labels Consistentes

**✅ HACER**: Usar labels estándar
```yaml
metadata:
  labels:
    app.kubernetes.io/name: user-service
    app.kubernetes.io/component: microservice
    app.kubernetes.io/part-of: ecommerce
    app.kubernetes.io/version: "0.1.0"
    app.kubernetes.io/managed-by: helm
```

### 7. Seguridad

**✅ HACER**: Correr como usuario no-root
```dockerfile
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

**✅ HACER**: Drop capabilities innecesarias
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

### 8. Versionado Semántico

**Versión de Chart**: `0.1.0` (sigue SemVer)  
**Versión de App**: `2025.12.01` (fecha del release)  
**Tag de Imagen**: `0.1.0-prod-multi` (versión + ambiente + arch)

### 9. Documentation as Code

- README.md en cada carpeta importante
- Comentarios en YAML complejos
- Helm NOTES.txt con instrucciones post-install

### 10. GitOps

- Toda infraestructura en Git
- Pull Requests para cambios
- CI/CD aplica automáticamente
- No cambios manuales con kubectl (excepto emergencias)

---

## 📚 Referencias

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)
- [12 Factor App](https://12factor.net/)

---

**Documento Mantenido Por**: DevOps Team  
**Última Actualización**: 2025-12-01  
**Próxima Revisión**: 2025-03-01  
**Versión**: 1.0

[🏠 Volver al README](../../README.md#documentación-de-infraestructura-como-código)
