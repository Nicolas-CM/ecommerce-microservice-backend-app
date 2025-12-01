[🏠 Volver al README](../../README.md#manual-de-operaciones-básico)

---

# Operations Manual
## Manual Básico de Operaciones

> **Proyecto**: E-commerce Microservices Backend  
> **Versión**: 1.0  
> **Fecha**: Diciembre 2025  
> **Audiencia**: DevOps Engineers, SRE, On-Call Team

---

## 📋 Índice

1. [Introducción](#introducción)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Despliegue y Configuración](#despliegue-y-configuración)
4. [Monitoreo y Alertas](#monitoreo-y-alertas)
5. [Operaciones Comunes](#operaciones-comunes)
6. [Troubleshooting](#troubleshooting)
7. [Procedimientos de Emergencia](#procedimientos-de-emergencia)
8. [Mantenimiento](#mantenimiento)
9. [Escalado](#escalado)
10. [Backup y Recuperación](#backup-y-recuperación)

---

## 🎯 Introducción

Este manual proporciona instrucciones operacionales para el sistema de microservicios de e-commerce desplegado en Azure Kubernetes Service (AKS). Está diseñado como referencia rápida para tareas de operación diaria, troubleshooting y respuesta a incidentes.

### Información del Sistema

```yaml
Nombre: ecommerce-microservice-backend-app
Plataforma: Azure Kubernetes Service (AKS)
Orquestación: Kubernetes 1.28
Gestión de Configuración: Helm 3
Contenedores: Docker (multi-arch: amd64/arm64)
CI/CD: GitHub Actions
Dominio: cuellarapp.online
Región: Azure East US
```

### Servicios Desplegados

| Servicio | Puerto | Propósito | Réplicas (Prod) |
|----------|--------|-----------|-----------------|
| **api-gateway** | 8080 | Enrutamiento y balanceo | 3 |
| **user-service** | 8081 | Gestión de usuarios | 3 |
| **product-service** | 8082 | Catálogo de productos | 3 |
| **order-service** | 8083 | Gestión de órdenes | 3 |
| **payment-service** | 8084 | Procesamiento de pagos | 5 |
| **shipping-service** | 8085 | Gestión de envíos | 2 |
| **favourite-service** | 8086 | Favoritos de usuario | 2 |
| **service-discovery** | 8761 | Eureka Server | 2 |
| **cloud-config** | 8888 | Config Server | 2 |
| **proxy-client** | 9090 | Cliente proxy | 1 |

### Contactos de Soporte

| Rol | Contacto | Horario | Escalación |
|-----|----------|---------|------------|
| **DevOps On-Call** | devops-oncall@company.com | 24/7 | PagerDuty |
| **Tech Lead** | techlead@company.com | 8am-6pm UTC | +1-555-0101 |
| **DBA** | dba@company.com | 8am-6pm UTC | +1-555-0102 |
| **Security Team** | security@company.com | 8am-6pm UTC | +1-555-0103 |

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Componentes

```
                        ┌─────────────────┐
                        │   Azure Load    │
                        │    Balancer     │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │   API Gateway   │
                        │   (Port 8080)   │
                        └────────┬────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
        ┌────────▼────────┐ ┌───▼────┐ ┌───────▼──────┐
        │  User Service   │ │Product │ │Order Service │
        │   (Port 8081)   │ │Service │ │ (Port 8083)  │
        └────────┬────────┘ │(8082)  │ └───────┬──────┘
                 │          └────┬───┘         │
        ┌────────▼────────┐      │    ┌────────▼──────┐
        │  PostgreSQL     │      │    │  Payment      │
        │  (Users DB)     │      │    │  Service      │
        └─────────────────┘      │    │  (8084)       │
                                 │    └────────┬──────┘
                        ┌────────▼────────┐    │
                        │  PostgreSQL     │    │
                        │  (Products DB)  │    │
                        └─────────────────┘    │
                                               │
                                    ┌──────────▼──────┐
                                    │  Shipping       │
                                    │  Service (8085) │
                                    └─────────────────┘
```

### Stack Tecnológico

**Backend**:
- Java 17 (Eclipse Temurin JRE)
- Spring Boot 3.2.0
- Spring Cloud 2023.0.0

**Base de Datos**:
- Azure Database for PostgreSQL Flexible Server
- Redis Cache (para sesiones)

**Infraestructura**:
- Azure Kubernetes Service (AKS)
- Azure Load Balancer
- Azure Container Registry (opcional) / GitHub Container Registry (GHCR)
- Azure Key Vault (secretos)

**Observabilidad**:
- Prometheus (métricas)
- Grafana (dashboards)
- Zipkin (distributed tracing)
- Azure Monitor / Log Analytics

---

## 🚀 Despliegue y Configuración

### Prerequisitos

```bash
# Herramientas necesarias
- kubectl (>= 1.28)
- helm (>= 3.12)
- Azure CLI (>= 2.50)
- Docker (>= 24.0)
- Git

# Verificar instalaciones
kubectl version --client
helm version
az version
docker --version
```

### Configuración Inicial

#### 1. Autenticación en Azure

```bash
# Login a Azure
az login

# Configurar suscripción
az account set --subscription "<subscription-id>"

# Obtener credenciales de AKS
az aks get-credentials \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --overwrite-existing

# Verificar contexto
kubectl config current-context
# Debe mostrar: ecommerce-aks-cluster
```

#### 2. Verificar Conectividad

```bash
# Listar nodos del cluster
kubectl get nodes
# Esperado: 2-3 nodos en Ready state

# Listar namespaces
kubectl get namespaces
# Debe incluir: prod, stage, dev, monitoring

# Ver pods en producción
kubectl get pods -n prod
```

### Despliegue con Helm

#### Deploy Completo (Producción)

```bash
# Navegar al directorio de Helm charts
cd k8s/helm/

# Verificar valores de configuración
cat values-prod.yaml
cat image-tags-prod.yaml

# Dry-run para validar
helm upgrade --install ecommerce-app ./ecommerce-chart \
  -f ./values-prod.yaml \
  -f ./image-tags-prod.yaml \
  -n prod \
  --dry-run --debug

# Deploy real
helm upgrade --install ecommerce-app ./ecommerce-chart \
  -f ./values-prod.yaml \
  -f ./image-tags-prod.yaml \
  -n prod \
  --wait \
  --timeout 10m

# Verificar rollout
kubectl rollout status deployment/api-gateway -n prod
kubectl rollout status deployment/user-service -n prod
kubectl rollout status deployment/product-service -n prod
# ... (resto de servicios)

# Verificar que todos los pods estén Running
kubectl get pods -n prod
```

#### Deploy de un Solo Servicio

```bash
# Actualizar solo una imagen específica
helm upgrade ecommerce-app ./ecommerce-chart \
  -f ./values-prod.yaml \
  -f ./image-tags-prod.yaml \
  --set userService.image.tag=0.2.0-prod-multi \
  -n prod

# O editar deployment directamente (temporal)
kubectl set image deployment/user-service \
  user-service=ghcr.io/nicolas-cm/user-service:0.2.0-prod-multi \
  -n prod
```

### Configuración de Variables de Ambiente

#### ConfigMap (Configuraciones No Sensibles)

```bash
# Ver ConfigMap actual
kubectl get configmap ecommerce-config -n prod -o yaml

# Editar ConfigMap
kubectl edit configmap ecommerce-config -n prod

# Aplicar cambios (requiere restart de pods)
kubectl rollout restart deployment/<service-name> -n prod
```

**Ejemplo de ConfigMap**:
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
```

#### Secrets (Configuraciones Sensibles)

```bash
# Ver secrets (valores encriptados)
kubectl get secrets -n prod

# Editar secret (base64 encoded)
kubectl edit secret db-credentials -n prod

# Crear secret desde literal
kubectl create secret generic api-keys \
  --from-literal=STRIPE_API_KEY=sk_live_xxx \
  --from-literal=SENDGRID_API_KEY=SG.xxx \
  -n prod

# Crear secret desde archivo
kubectl create secret generic db-connection \
  --from-file=connection-string=./db-conn.txt \
  -n prod
```

**Ejemplo de Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: prod
type: Opaque
data:
  DB_USERNAME: cG9zdGdyZXM=  # base64 de "postgres"
  DB_PASSWORD: c3VwZXJzZWNyZXQ=  # base64 de "supersecret"
```

### Health Checks

**Configuración de Liveness y Readiness Probes**:

```yaml
# En deployment.yaml de cada servicio
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
```

**Verificar Health Checks**:
```bash
# Dentro del cluster
kubectl exec -n prod deployment/user-service -- \
  curl -s http://localhost:8080/actuator/health

# Desde fuera (si expuesto)
curl http://cuellarapp.online/api/users/actuator/health
```

---

## 📊 Monitoreo y Alertas

### Métricas con Prometheus

#### Acceder a Prometheus

```bash
# Port-forward para acceso local
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Abrir en navegador
http://localhost:9090
```

#### Queries Útiles

**Error Rate**:
```promql
# Porcentaje de errores (status 5xx)
sum(rate(http_server_requests_total{status=~"5.."}[5m])) by (service) 
/ 
sum(rate(http_server_requests_total[5m])) by (service) * 100
```

**Response Time P95**:
```promql
histogram_quantile(0.95, 
  sum(rate(http_server_requests_seconds_bucket[5m])) by (le, service)
)
```

**Request Rate (RPS)**:
```promql
sum(rate(http_server_requests_total[5m])) by (service)
```

**CPU Usage per Pod**:
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="prod"}[5m])) by (pod)
```

**Memory Usage per Pod**:
```promql
container_memory_working_set_bytes{namespace="prod"} / 1024 / 1024
```

### Dashboards con Grafana

#### Acceder a Grafana

```bash
# Port-forward
kubectl port-forward -n monitoring svc/grafana 3000:80

# Credenciales default
Username: admin
Password: (obtener de secret)

kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

#### Dashboards Principales

1. **API Overview**
   - Total RPS
   - Error rate
   - P50/P95/P99 latencies
   - Top endpoints

2. **Service Health**
   - Pod status por servicio
   - Restarts
   - CPU/Memory usage
   - Health check failures

3. **Infrastructure**
   - Node CPU/Memory
   - Disk usage
   - Network I/O
   - Pod distribution

4. **Business Metrics**
   - Orders per minute
   - Revenue per hour
   - Active users
   - Cart abandonment rate

### Logs

#### Ver Logs de un Servicio

```bash
# Logs en tiempo real
kubectl logs -n prod deployment/user-service -f

# Logs de las últimas 2 horas
kubectl logs -n prod deployment/user-service --since=2h

# Logs de todos los pods de un servicio
kubectl logs -n prod -l app=user-service --all-containers=true

# Filtrar por nivel de error
kubectl logs -n prod deployment/user-service | grep -i "error\|exception"

# Guardar logs a archivo
kubectl logs -n prod deployment/user-service --since=24h > user-service-logs.txt
```

#### Logs Agregados (Azure Monitor)

```bash
# Query en Log Analytics (Kusto Query Language)
ContainerLog
| where TimeGenerated > ago(1h)
| where Namespace == "prod"
| where ContainerName == "user-service"
| where LogEntry contains "ERROR"
| project TimeGenerated, LogEntry
| order by TimeGenerated desc
| take 100
```

### Alertas

#### Alertas Configuradas (Prometheus Alertmanager)

**Critical Alerts (PagerDuty)**:
- Pod CrashLoopBackOff (>2 restarts en 5 min)
- Service Down (health check failed)
- Error Rate >5%
- Response Time P95 >2s

**Warning Alerts (Slack)**:
- Error Rate >2%
- Response Time P95 >800ms
- CPU Usage >85%
- Memory Usage >90%

#### Ver Alertas Activas

```bash
# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093

# Ver en navegador
http://localhost:9093/#/alerts

# O via API
curl -s http://localhost:9093/api/v2/alerts | jq
```

---

## 🔧 Operaciones Comunes

### Escalar Réplicas

```bash
# Escalar manualmente un deployment
kubectl scale deployment/payment-service --replicas=5 -n prod

# Verificar
kubectl get deployment payment-service -n prod

# Escalar múltiples servicios
kubectl scale deployment/user-service deployment/product-service \
  --replicas=4 -n prod
```

### Reiniciar un Servicio

```bash
# Restart (rolling restart) de un deployment
kubectl rollout restart deployment/user-service -n prod

# Verificar progreso
kubectl rollout status deployment/user-service -n prod

# Restart de todos los deployments
kubectl rollout restart deployment -n prod
```

### Actualizar Configuración

```bash
# 1. Editar ConfigMap
kubectl edit configmap ecommerce-config -n prod

# 2. Aplicar cambios reiniciando pods
kubectl rollout restart deployment/user-service -n prod

# O crear ConfigMap desde archivo
kubectl create configmap ecommerce-config \
  --from-file=application.yml \
  -n prod \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Ver Información de Recursos

```bash
# Uso de recursos por pod
kubectl top pods -n prod

# Uso de recursos por nodo
kubectl top nodes

# Detalles de un pod específico
kubectl describe pod <pod-name> -n prod

# Ver eventos recientes
kubectl get events -n prod --sort-by='.lastTimestamp' | tail -20

# Ver estado de todos los recursos
kubectl get all -n prod
```

### Acceder a un Pod (Debug)

```bash
# Abrir shell en un pod
kubectl exec -it deployment/user-service -n prod -- /bin/bash

# Ejecutar comando único
kubectl exec -n prod deployment/user-service -- ps aux

# Copiar archivos desde pod
kubectl cp prod/<pod-name>:/app/logs/app.log ./local-app.log

# Copiar archivos a pod
kubectl cp ./config.yml prod/<pod-name>:/app/config/config.yml
```

### Port-Forward para Testing

```bash
# Acceder a servicio localmente
kubectl port-forward -n prod svc/user-service 8081:8080

# Ahora se puede acceder en: http://localhost:8081

# Port-forward con múltiples puertos
kubectl port-forward -n prod svc/api-gateway 8080:8080 9090:9090
```

---

## 🔍 Troubleshooting

### Pod en CrashLoopBackOff

**Síntoma**: Pod reiniciándose constantemente

**Diagnóstico**:
```bash
# Ver estado del pod
kubectl get pod <pod-name> -n prod

# Ver logs del contenedor fallido
kubectl logs <pod-name> -n prod --previous

# Describir pod para ver eventos
kubectl describe pod <pod-name> -n prod
```

**Causas Comunes**:
1. **Error en aplicación**: Ver logs para exception
2. **Health check fallando**: Revisar /actuator/health
3. **Configuración incorrecta**: Verificar ConfigMap/Secret
4. **Recursos insuficientes**: OOMKilled (Out of Memory)

**Soluciones**:
```bash
# Si es configuración
kubectl edit configmap ecommerce-config -n prod
kubectl rollout restart deployment/<service> -n prod

# Si es OOM, incrementar límites de memoria
kubectl edit deployment/<service> -n prod
# Modificar: resources.limits.memory: "1Gi"

# Si es bug de aplicación, revertir a versión anterior
helm rollback ecommerce-app -n prod
```

### Servicio No Responde (Timeout)

**Síntoma**: Requests a servicio timeout o HTTP 503

**Diagnóstico**:
```bash
# Ver si pods están Running
kubectl get pods -n prod -l app=<service>

# Ver si service tiene endpoints
kubectl get endpoints <service> -n prod

# Probar conectividad interna
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n prod -- \
  curl -v http://<service>:8080/actuator/health

# Ver logs
kubectl logs -n prod deployment/<service> --tail=100
```

**Causas Comunes**:
1. **Pods no Ready**: Readiness probe fallando
2. **Service selector incorrecto**: No encuentra pods
3. **Network policy bloqueando**: Verificar policies
4. **Database connection timeout**: Pool exhausted

**Soluciones**:
```bash
# Verificar health endpoint
kubectl exec -n prod deployment/<service> -- \
  curl http://localhost:8080/actuator/health

# Verificar selector de service
kubectl get service <service> -n prod -o yaml
kubectl get pods -n prod --show-labels

# Reiniciar pods
kubectl rollout restart deployment/<service> -n prod
```

### Alta Latencia / Performance Degradado

**Síntoma**: Response times >1s, usuarios reportan lentitud

**Diagnóstico**:
```bash
# Ver uso de CPU/Memory
kubectl top pods -n prod

# Ver métricas en Prometheus
# Query: histogram_quantile(0.95, http_server_requests_seconds_bucket)

# Ver slow queries en base de datos
# Conectar a PostgreSQL y ejecutar:
SELECT query, calls, mean_exec_time, max_exec_time 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

# Ver logs para slow requests
kubectl logs -n prod deployment/<service> | grep "took more than"
```

**Causas Comunes**:
1. **DB queries no optimizadas**: Sin índices
2. **Connection pool exhausted**: Max connections alcanzado
3. **CPU throttling**: Pods con limits muy bajos
4. **Memory leaks**: Garbage collection constante
5. **N+1 queries**: Consultas ineficientes

**Soluciones**:
```bash
# Escalar horizontalmente
kubectl scale deployment/<service> --replicas=5 -n prod

# Incrementar recursos
kubectl edit deployment/<service> -n prod
# Ajustar: resources.requests y resources.limits

# Habilitar HPA (Horizontal Pod Autoscaler)
kubectl autoscale deployment/<service> \
  --cpu-percent=70 \
  --min=3 --max=10 \
  -n prod

# Verificar conexiones de BD
# En ConfigMap, incrementar: DB_POOL_SIZE
```

### Error de Base de Datos

**Síntoma**: Logs muestran SQLException, connection refused

**Diagnóstico**:
```bash
# Ver si secret de BD existe
kubectl get secret db-credentials -n prod

# Verificar conectividad a BD
kubectl run -it --rm psql-debug --image=postgres:15 --restart=Never -n prod -- \
  psql -h <db-host> -U <username> -d ecommerce

# Ver logs de aplicación
kubectl logs -n prod deployment/<service> | grep -i "sql\|database"
```

**Causas Comunes**:
1. **Credenciales incorrectas**: Secret mal configurado
2. **Network policy**: Cluster no puede alcanzar BD
3. **BD caída**: Azure Database offline
4. **Connection pool exhausted**: Max connections alcanzado
5. **Firewall**: IP de AKS no whitelisted en Azure

**Soluciones**:
```bash
# Verificar secret
kubectl get secret db-credentials -n prod -o yaml

# Verificar firewall de Azure Database
az postgres flexible-server firewall-rule list \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod

# Agregar regla de firewall si necesario
az postgres flexible-server firewall-rule create \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod \
  --rule-name AllowAKS \
  --start-ip-address <aks-outbound-ip> \
  --end-ip-address <aks-outbound-ip>

# Verificar estado de BD en Azure Portal
az postgres flexible-server show \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod
```

### Pods Pending (No se Programan)

**Síntoma**: Pods en estado Pending indefinidamente

**Diagnóstico**:
```bash
# Ver eventos del pod
kubectl describe pod <pod-name> -n prod

# Ver capacidad de nodos
kubectl describe nodes
```

**Causas Comunes**:
1. **Insufficient CPU/Memory**: Nodos sin recursos
2. **Node Selector/Affinity**: No hay nodos que cumplan condición
3. **Taints/Tolerations**: Pod no tolera taint de nodo
4. **PVC no creado**: PersistentVolumeClaim pending

**Soluciones**:
```bash
# Escalar cluster (agregar nodos)
az aks scale \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --node-count 4

# Reducir recursos del pod
kubectl edit deployment/<service> -n prod
# Reducir: resources.requests

# Ver detalles de PVC si es storage issue
kubectl get pvc -n prod
kubectl describe pvc <pvc-name> -n prod
```

---

## 🚨 Procedimientos de Emergencia

### Incidente SEV-1: Sistema Completamente Caído

**1. Declarar Incidente (0-2 min)**
```bash
# Notificar en Slack
/incident declare-sev1 "Production complete outage"

# Convocar equipo
# PagerDuty automáticamente alerta a on-call

# Iniciar bridge call
# Link en #incidents channel
```

**2. Diagnóstico Rápido (2-5 min)**
```bash
# Verificar pods
kubectl get pods -n prod

# Ver eventos críticos
kubectl get events -n prod --sort-by='.lastTimestamp' | grep -i error | tail -20

# Verificar nodos
kubectl get nodes

# Ver logs de API Gateway
kubectl logs -n prod deployment/api-gateway --tail=100
```

**3. Acciones Inmediatas (5-15 min)**

**Opción A: Rollback si deploy reciente**
```bash
# Ver historial de Helm
helm history ecommerce-app -n prod

# Rollback a última versión estable
helm rollback ecommerce-app -n prod

# Monitorear
kubectl get pods -n prod -w
```

**Opción B: Reinicio de emergencia**
```bash
# Restart todos los servicios
kubectl rollout restart deployment -n prod

# Si persiste, eliminar y recrear pods
kubectl delete pods -n prod --all
```

**Opción C: Problema de infraestructura**
```bash
# Verificar nodos
kubectl get nodes
kubectl describe nodes | grep -i "pressure\|condition"

# Si nodos unhealthy, escalar cluster
az aks scale \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --node-count 5
```

**4. Validación (15-30 min)**
```bash
# Health checks
for svc in api-gateway user-service product-service order-service payment-service; do
  echo "=== $svc ==="
  kubectl exec -n prod deployment/$svc -- curl -s http://localhost:8080/actuator/health | jq
done

# Smoke tests
newman run postman-collections/smoke-tests.json \
  --environment postman-collections/prod-env.json
```

### Incidente SEV-2: Funcionalidad Crítica Degradada

**Escenario**: Servicio de pagos fallando pero resto OK

**1. Aislar Servicio Problemático**
```bash
# Escalar a 0 el servicio fallido (circuit breaker)
kubectl scale deployment/payment-service --replicas=0 -n prod

# Activar maintenance mode en API Gateway
kubectl set env deployment/api-gateway \
  PAYMENT_SERVICE_ENABLED=false \
  -n prod
```

**2. Diagnóstico Detallado**
```bash
# Ver logs del servicio
kubectl logs -n prod deployment/payment-service --all-containers=true

# Verificar dependencias externas
kubectl exec -n prod deployment/payment-service -- \
  curl -v https://api.stripe.com/v1/health
```

**3. Resolución**
```bash
# Si es bug de código, rollback selectivo
helm upgrade ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./values-prod.yaml \
  --set paymentService.image.tag=0.1.0-prod-multi-previous \
  -n prod

# Si es config, corregir
kubectl edit configmap ecommerce-config -n prod
kubectl rollout restart deployment/payment-service -n prod

# Restaurar réplicas
kubectl scale deployment/payment-service --replicas=5 -n prod
```

### Pérdida de Datos (Data Loss)

**Escenario**: Migración corrompió datos, usuarios reportan pérdida

**STOP EVERYTHING - No hacer cambios adicionales**

**1. Activar Modo Solo Lectura**
```bash
# Escalar servicios write a 0
kubectl scale deployment/user-service --replicas=0 -n prod
kubectl scale deployment/order-service --replicas=0 -n prod

# Mantener servicios read
kubectl scale deployment/product-service --replicas=3 -n prod
```

**2. Evaluar Daño**
```bash
# Conectar a BD
psql -h ecommerce-db-prod.postgres.database.azure.com -U adminuser -d ecommerce

# Contar registros
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders WHERE created_at >= '2025-12-01';

# Comparar con backup
# (datos esperados vs actuales)
```

**3. Restaurar desde Backup (PITR)**
```bash
# Crear servidor restaurado
az postgres flexible-server restore \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod-restored \
  --restore-point-in-time "2025-12-01T04:00:00Z" \
  --source-server /subscriptions/<sub-id>/resourceGroups/ecommerce-prod-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/ecommerce-db-prod

# WAIT 15-20 minutos para restore completo

# Verificar datos restaurados
psql -h ecommerce-db-prod-restored.postgres.database.azure.com -U adminuser -d ecommerce
SELECT COUNT(*) FROM users;

# Si correcto, actualizar connection string
kubectl edit secret db-credentials -n prod
# Cambiar host a: ecommerce-db-prod-restored.postgres.database.azure.com

# Reiniciar servicios
kubectl rollout restart deployment -n prod
```

**4. Comunicación**
```
Subject: Service Restored - Data Recovery Completed

We experienced a data integrity issue today from [start] to [end].

IMPACT:
- [number] users affected
- [functionality] temporarily unavailable

RESOLUTION:
- Database restored from backup (data as of [timestamp])
- All services operational
- Data validated by team

DATA LOSS:
- Transactions between [time1] and [time2] lost
- Users should re-submit orders if placed during window
- Support team notified to assist affected users

Apologies for the inconvenience.
```

---

## 🔧 Mantenimiento

### Mantenimiento Programado

**Ventana de Mantenimiento Recomendada**: Domingos 02:00-06:00 UTC (tráfico bajo)

#### Checklist Pre-Mantenimiento

```markdown
- [ ] Notificar a stakeholders (72h antes)
- [ ] Crear backup manual de bases de datos
- [ ] Documentar versiones actuales de todos los servicios
- [ ] Preparar plan de rollback
- [ ] Confirmar equipo on-call disponible
- [ ] Actualizar status page: "Maintenance scheduled"
```

#### Actualización de Dependencias

```bash
# 1. Actualizar imagen base en Dockerfile
# FROM eclipse-temurin:17-jre -> eclipse-temurin:17.0.9-jre

# 2. Build nuevas imágenes
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/nicolas-cm/user-service:0.2.0-prod-multi \
  --push .

# 3. Actualizar image-tags-prod.yaml
# userService: "0.2.0-prod-multi"

# 4. Deploy con rolling update
helm upgrade ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./values-prod.yaml \
  -f ./image-tags-prod.yaml \
  -n prod \
  --wait

# 5. Monitorear por 30 minutos
watch kubectl get pods -n prod
```

#### Actualización de Kubernetes

```bash
# Ver versiones disponibles
az aks get-upgrades \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster

# Upgrade control plane
az aks upgrade \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --kubernetes-version 1.29.0 \
  --control-plane-only

# Upgrade node pool
az aks nodepool upgrade \
  --resource-group ecommerce-prod-rg \
  --cluster-name ecommerce-aks-cluster \
  --name agentpool \
  --kubernetes-version 1.29.0

# Verificar
kubectl get nodes
kubectl version
```

#### Rotación de Secretos

```bash
# 1. Generar nueva contraseña de BD
NEW_PASSWORD=$(openssl rand -base64 32)

# 2. Actualizar en Azure Database
az postgres flexible-server update \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod \
  --admin-password "$NEW_PASSWORD"

# 3. Actualizar secret en Kubernetes
kubectl create secret generic db-credentials \
  --from-literal=DB_PASSWORD="$NEW_PASSWORD" \
  -n prod \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Reiniciar pods para aplicar
kubectl rollout restart deployment -n prod

# 5. Validar conectividad
kubectl logs -n prod deployment/user-service | grep -i "database connection"
```

### Limpieza de Recursos

#### Limpiar Imágenes Antiguas (GHCR)

```bash
# Listar imágenes
gh api -X GET /user/packages/container/user-service/versions

# Eliminar versiones antiguas (>30 días)
# (Script de automatización recomendado)
```

#### Limpiar Pods Evicted/Failed

```bash
# Eliminar pods en estado Failed o Evicted
kubectl delete pods -n prod --field-selector status.phase=Failed
kubectl delete pods -n prod --field-selector status.phase=Evicted
```

#### Limpiar Recursos No Utilizados

```bash
# Helm releases antiguas (mantener últimas 5)
helm history ecommerce-app -n prod --max 10

# Eliminar revisiones antiguas manualmente si necesario
# (Helm mantiene historial automáticamente)

# Limpiar PVCs no utilizados
kubectl get pvc -n prod
# Eliminar manualmente si no están bound
```

---

## 📈 Escalado

### Escalado Manual

```bash
# Escalar deployment
kubectl scale deployment/payment-service --replicas=10 -n prod

# Verificar
kubectl get deployment payment-service -n prod
```

### Horizontal Pod Autoscaler (HPA)

#### Configurar HPA

```bash
# Crear HPA basado en CPU
kubectl autoscale deployment payment-service \
  --cpu-percent=70 \
  --min=3 --max=15 \
  -n prod

# Crear HPA basado en múltiples métricas (YAML)
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payment-service-hpa
  namespace: prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payment-service
  minReplicas: 3
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 30
      selectPolicy: Max
EOF
```

#### Ver Estado de HPA

```bash
# Listar HPAs
kubectl get hpa -n prod

# Detalles de un HPA
kubectl describe hpa payment-service-hpa -n prod

# Monitorear en tiempo real
watch kubectl get hpa -n prod
```

### Cluster Autoscaler

El cluster autoscaler de AKS agrega/elimina nodos automáticamente basado en demanda.

```bash
# Verificar que está habilitado
az aks show \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --query "autoScalerProfile"

# Configurar límites de autoscaling
az aks update \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-aks-cluster \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10
```

### Vertical Pod Autoscaler (VPA)

VPA ajusta automáticamente CPU/memory requests.

```bash
# Instalar VPA (si no está)
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-up.sh

# Crear VPA para un deployment
kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: user-service-vpa
  namespace: prod
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  updatePolicy:
    updateMode: "Auto"
EOF

# Ver recomendaciones
kubectl describe vpa user-service-vpa -n prod
```

---

## 💾 Backup y Recuperación

### Backup de Base de Datos

#### Backups Automáticos (Azure)

Azure Database for PostgreSQL realiza backups automáticos.

```bash
# Ver configuración de backup
az postgres flexible-server show \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod \
  --query "backup"

# Output:
# {
#   "backupRetentionDays": 7,
#   "geoRedundantBackup": "Disabled"
# }

# Extender retención a 35 días
az postgres flexible-server update \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod \
  --backup-retention 35
```

#### Backup Manual (pg_dump)

```bash
# Backup completo
pg_dump -h ecommerce-db-prod.postgres.database.azure.com \
  -U adminuser \
  -d ecommerce \
  -F c \
  -b \
  -v \
  -f ecommerce_backup_$(date +%Y%m%d_%H%M%S).dump

# Backup solo schema
pg_dump -h ecommerce-db-prod.postgres.database.azure.com \
  -U adminuser \
  -d ecommerce \
  --schema-only \
  -f ecommerce_schema_$(date +%Y%m%d).sql

# Upload a Azure Blob Storage
az storage blob upload \
  --account-name ecommercestorprod \
  --container-name backups \
  --name ecommerce_backup_$(date +%Y%m%d_%H%M%S).dump \
  --file ./ecommerce_backup_*.dump
```

### Restauración de Base de Datos

#### Restauración PITR (Point-in-Time Recovery)

```bash
# Restaurar a punto específico en el tiempo
az postgres flexible-server restore \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod-restored-20251201 \
  --restore-point-in-time "2025-12-01T04:00:00Z" \
  --source-server /subscriptions/<sub-id>/resourceGroups/ecommerce-prod-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/ecommerce-db-prod

# Tiempo estimado: 15-30 minutos
```

#### Restauración desde Dump

```bash
# Crear nueva base de datos
psql -h ecommerce-db-prod.postgres.database.azure.com \
  -U adminuser \
  -c "CREATE DATABASE ecommerce_restored;"

# Restaurar dump
pg_restore -h ecommerce-db-prod.postgres.database.azure.com \
  -U adminuser \
  -d ecommerce_restored \
  -v \
  ecommerce_backup_20251201_040000.dump

# Validar
psql -h ecommerce-db-prod.postgres.database.azure.com \
  -U adminuser \
  -d ecommerce_restored \
  -c "SELECT COUNT(*) FROM users;"
```

### Backup de Configuración de Kubernetes

```bash
# Exportar todos los recursos de prod namespace
kubectl get all -n prod -o yaml > prod-backup-$(date +%Y%m%d).yaml

# Exportar ConfigMaps
kubectl get configmap -n prod -o yaml > prod-configmaps-$(date +%Y%m%d).yaml

# Exportar Secrets (encriptados)
kubectl get secrets -n prod -o yaml > prod-secrets-$(date +%Y%m%d).yaml

# Exportar Helm values
helm get values ecommerce-app -n prod > helm-values-backup-$(date +%Y%m%d).yaml

# Backup completo con Velero (recomendado para producción)
velero backup create prod-backup-$(date +%Y%m%d) \
  --include-namespaces prod \
  --snapshot-volumes
```

### Disaster Recovery Plan

**RTO** (Recovery Time Objective): 2 horas  
**RPO** (Recovery Point Objective): 5 minutos

#### Escenario: Pérdida Completa de Cluster

**1. Provisionar nuevo cluster AKS (30 min)**
```bash
# Ejecutar Terraform para recrear infraestructura
cd terraform/
terraform apply
```

**2. Restaurar configuración (15 min)**
```bash
# Aplicar backups de Kubernetes
kubectl apply -f prod-backup-latest.yaml

# O restaurar con Velero
velero restore create --from-backup prod-backup-latest
```

**3. Restaurar base de datos (30 min)**
```bash
# PITR a último punto disponible
az postgres flexible-server restore \
  --resource-group ecommerce-prod-rg \
  --name ecommerce-db-prod-dr \
  --restore-point-in-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --source-server <original-server-id>
```

**4. Deploy aplicaciones (20 min)**
```bash
# Deploy con Helm
helm install ecommerce-app ./k8s/helm/ecommerce-chart \
  -f ./values-prod.yaml \
  -f ./image-tags-prod.yaml \
  -n prod
```

**5. Validación completa (25 min)**
```bash
# Health checks, smoke tests, etc.
```

**Total Recovery Time**: ~2 horas ✅ (dentro de RTO)

---

## 📚 Referencias Rápidas

### Comandos Útiles Rápidos

```bash
# Ver todo en producción
kubectl get all -n prod

# Logs de últimos 10 minutos con errores
kubectl logs -n prod --since=10m --all-containers=true | grep -i error

# Top pods por uso de recursos
kubectl top pods -n prod --sort-by=cpu
kubectl top pods -n prod --sort-by=memory

# Reiniciar todo en rolling fashion
kubectl rollout restart deployment -n prod

# Ver versión de imágenes desplegadas
kubectl get pods -n prod -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Port-forward para acceso rápido
kubectl port-forward -n prod svc/api-gateway 8080:8080

# Ejecutar comando en todos los pods de un servicio
for pod in $(kubectl get pods -n prod -l app=user-service -o name); do
  kubectl exec -n prod $pod -- curl -s http://localhost:8080/actuator/info | jq
done
```

### Enlaces Importantes

- **GitHub Repository**: https://github.com/Nicolas-CM/ecommerce-microservice-backend-app
- **Azure Portal**: https://portal.azure.com
- **Grafana Dashboards**: http://monitoring.cuellarapp.online
- **Prometheus**: http://prometheus.cuellarapp.online
- **API Documentation**: http://cuellarapp.online/swagger-ui.html
- **Status Page**: https://status.cuellarapp.online

### Documentación Relacionada

- [Change Management Process](./change-management-process.md)
- [Rollback Plan](./rollback-plan.md)
- [Testing Analysis Report](./testing-analysis-report.md)
- [Infrastructure as Code Documentation](./infrastructure-documentation.md)

---

**Documento Mantenido Por**: DevOps Team  
**Última Actualización**: 2025-12-01  
**Próxima Revisión**: 2025-03-01  
**Versión**: 1.0

[🏠 Volver al README](../../README.md#manual-de-operaciones-básico)
