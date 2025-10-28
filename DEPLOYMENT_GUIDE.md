# 🚀 Guía de Despliegue en Minikube con GitHub Actions

## 📋 Pre-requisitos

### Herramientas Necesarias
- ✅ Docker Desktop
- ✅ Minikube
- ✅ Kubectl
- ✅ Java 21
- ✅ Maven
- ✅ Git
- ✅ Python 3.11+ (para Locust)

---

## 🎯 FASE 1: Setup Inicial

### 1.1 Instalar Minikube

```powershell
# Instalar Minikube
choco install minikube

# Verificar instalación
minikube version
```

### 1.2 Instalar Kubectl

```powershell
# Instalar kubectl
choco install kubernetes-cli

# Verificar instalación
kubectl version --client
```

### 1.3 Iniciar Minikube

```powershell
# Iniciar Minikube con recursos adecuados
minikube start --driver=docker --cpus=4 --memory=16384 --disk-size=20g

# Verificar estado
minikube status
kubectl cluster-info
```

### 1.4 Habilitar Addons

```powershell
# Registry interno
minikube addons enable registry

# Ingress controller
minikube addons enable ingress

# Métricas
minikube addons enable metrics-server

# Dashboard (opcional)
minikube addons enable dashboard

# Ver todos los addons
minikube addons list
```

---

## 🔨 FASE 2: Compilar el Proyecto

### 2.1 Compilar Todos los Servicios

```powershell
# Desde la raíz del proyecto
.\mvnw.cmd clean package -DskipTests
```

### 2.2 Verificar Compilación

```powershell
# Verificar que los JARs se generaron
dir user-service\target\*.jar
dir product-service\target\*.jar
dir order-service\target\*.jar
```

---

## 🐳 FASE 3: Construir Imágenes Docker

### 3.1 Configurar Docker para Minikube

Debe ser en una terminal de Powershell

```powershell
# Configurar terminal para usar Docker de Minikube
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Verificar que estás usando Docker de Minikube
docker ps
```

### 3.2 Construir Imágenes

Cambiar los Dockerfile para que apuntaran bien, por ejemplo:
Cambiar: 

ENV SPRING_PROFILES_ACTIVE dev
COPY service-discovery/ .
ADD service-discovery/target/service-discovery-v${PROJECT_VERSION}.jar service-discovery.jar

Por:
ENV SPRING_PROFILES_ACTIVE=dev
ADD target/service-discovery-v${PROJECT_VERSION}.jar service-discovery.jar


```powershell
# Ejecutar script de build
.\build-images.ps1
```

### 3.3 Verificar Imágenes

```powershell
# Listar imágenes en Minikube
docker images | findstr "service"
```

---

## ☸️ FASE 4: Generar Manifiestos de Kubernetes

### 4.1 Generar Manifiestos para Todos los Servicios

```powershell
# Ejecutar script generador
.\generate-k8s-manifests.ps1 #NO NO NO hacer si ya se tienen los .yaml
```

### 4.2 Verificar Manifiestos

```powershell
# Listar archivos generados
dir k8s\base\*.yaml
```

---

## 🚀 FASE 5: Desplegar en Minikube

### 5.1 Crear Namespace

```powershell
kubectl apply -f k8s/base/namespace.yaml
```

### 5.2 Crear ConfigMaps

```powershell
kubectl apply -f k8s/base/configmaps.yaml -n ecommerce
```

### 5.3 Desplegar Infraestructura (en orden y esperar hasta que cada uno esté arriba 1/1 READY) kubectl get pods -n ecommerce

```powershell
# 1. Zipkin
kubectl apply -f k8s/base/zipkin.yaml -n ecommerce

# 2. Service Discovery (Eureka) (DEMORADÍSIMO)
kubectl apply -f k8s/base/service-discovery.yaml -n ecommerce

# 3. Cloud Config
kubectl apply -f k8s/base/cloud-config.yaml -n ecommerce

# Esperar a que estén listos
kubectl wait --for=condition=available --timeout=180s deployment/service-discovery -n ecommerce
kubectl wait --for=condition=available --timeout=180s deployment/cloud-config -n ecommerce
```

### 5.4 Desplegar API Gateway y Proxy

```powershell
kubectl apply -f k8s/base/api-gateway.yaml -n ecommerce
kubectl apply -f k8s/base/proxy-client.yaml -n ecommerce
```

### 5.5 Desplegar Microservicios de Negocio

```powershell
kubectl apply -f k8s/base/user-service.yaml -n ecommerce
kubectl apply -f k8s/base/product-service.yaml -n ecommerce
kubectl apply -f k8s/base/order-service.yaml -n ecommerce
kubectl apply -f k8s/base/payment-service.yaml -n ecommerce
kubectl apply -f k8s/base/shipping-service.yaml -n ecommerce
kubectl apply -f k8s/base/favourite-service.yaml -n ecommerce
```

#### PARA ELIMINAR TODOS (SOLO PRUEBA)

```powershell
kubectl delete -f k8s/base/zipkin.yaml -n ecommerce
kubectl delete -f k8s/base/service-discovery.yaml -n ecommerce
kubectl delete -f k8s/base/cloud-config.yaml -n ecommerce

kubectl delete -f k8s/base/api-gateway.yaml -n ecommerce
kubectl delete -f k8s/base/proxy-client.yaml -n ecommerce

kubectl delete -f k8s/base/user-service.yaml -n ecommerce
kubectl delete -f k8s/base/product-service.yaml -n ecommerce
kubectl delete -f k8s/base/order-service.yaml -n ecommerce
kubectl delete -f k8s/base/payment-service.yaml -n ecommerce
kubectl delete -f k8s/base/shipping-service.yaml -n ecommerce
kubectl delete -f k8s/base/favourite-service.yaml -n ecommerce
```

### 5.6 Verificar Despliegue

```powershell
# Ver todos los pods
kubectl get pods -n ecommerce

# Ver todos los servicios
kubectl get svc -n ecommerce

# Ver deployments
kubectl get deployments -n ecommerce

# Ver logs de un pod (ejemplo)
kubectl logs -n ecommerce deployment/user-service
```

---

## 🧪 FASE 6: Probar los Servicios

### 6.1 Port-Forward para Acceder Localmente

```powershell
# Eureka Dashboard
kubectl port-forward -n ecommerce svc/service-discovery 8761:8761

# User Service
kubectl port-forward -n ecommerce svc/user-service 8700:8700

# Product Service
kubectl port-forward -n ecommerce svc/product-service 8500:8500

# Zipkin
kubectl port-forward -n ecommerce svc/zipkin 9411:9411
```

### 6.2 Probar Endpoints

```powershell
# Eureka Dashboard
curl http://localhost:8761

# User Service
curl http://localhost:8700/user-service/api/users

# Product Service
curl http://localhost:8500/product-service/api/products

# Zipkin
curl http://localhost:9411
```

---

## ⚡ FASE 7: Pruebas de Rendimiento

### 7.1 Instalar Locust

```powershell
pip install locust
```

### 7.2 Ejecutar Pruebas

```powershell
# Con port-forward activo en otra terminal
cd tests/performance

# Ejecutar pruebas
locust -f locustfile.py --headless --users 50 --spawn-rate 5 --run-time 5m --host http://localhost:8500

# O con UI web
locust -f locustfile.py --host http://localhost:8500
# Luego abrir http://localhost:8089
```

---

## 🔄 FASE 8: Configurar GitHub Actions

### 8.1 Crear Ramas

```powershell
# Crear rama dev
git checkout -b dev
git push origin dev

# Crear rama stage
git checkout -b stage
git push origin stage
```

### 8.2 Hacer Push de los Workflows

```powershell
# Asegurarse de que los workflows estén en el repo
git add .github/workflows/
git add k8s/
git add tests/
git add *.ps1
git commit -m "Add GitHub Actions workflows and K8s manifests"
git push origin master
```

### 8.3 Ejecutar Workflows

1. Ve a GitHub → Tu repositorio → Actions
2. Verás 3 workflows:
   - **DEV** - Build & Basic Tests
   - **STAGE** - Full Tests & Deploy to Minikube
   - **PROD** - Full Pipeline with Performance Tests

3. Para ejecutar manualmente:
   - Clic en el workflow
   - Clic en "Run workflow"
   - Seleccionar rama
   - Clic en "Run workflow"

---

## 📊 FASE 9: Monitoreo

### 9.1 Dashboard de Kubernetes

```powershell
# Abrir dashboard
minikube dashboard
```

### 9.2 Ver Logs en Tiempo Real

```powershell
# Logs de un servicio específico
kubectl logs -f -n ecommerce deployment/user-service

# Logs de todos los pods con label
kubectl logs -f -n ecommerce -l app=user-service
```

### 9.3 Describir Recursos

```powershell
# Descripción detallada de un pod
kubectl describe pod -n ecommerce <pod-name>

# Descripción de un deployment
kubectl describe deployment -n ecommerce user-service
```

---

## 🔧 Troubleshooting

### Pod No Inicia

```powershell
# Ver eventos
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Ver logs del pod
kubectl logs -n ecommerce <pod-name>

# Describir el pod para ver errores
kubectl describe pod -n ecommerce <pod-name>
```

### Imagen No Encontrada

```powershell
# Verificar que la imagen existe en Minikube
minikube ssh
docker images

# Si no está, reconstruir y cargar
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
.\build-images.ps1
```

### Servicio No Responde

```powershell
# Verificar que el pod está running
kubectl get pods -n ecommerce

# Verificar logs
kubectl logs -n ecommerce deployment/<service-name>

# Verificar el servicio
kubectl get svc -n ecommerce
kubectl describe svc -n ecommerce <service-name>
```

---

## 🧹 Limpieza

### Eliminar Todo

```powershell
# Eliminar namespace (elimina todo dentro)
kubectl delete namespace ecommerce

# O detener Minikube completamente
minikube stop

# O eliminar el cluster
minikube delete
```

---

## 📝 Notas Importantes

1. **Recursos**: Minikube requiere al menos 4 CPUs y 8GB RAM
2. **Tiempo**: El despliegue completo puede tardar 5-10 minutos
3. **Imágenes**: Usa `imagePullPolicy: Never` para imágenes locales
4. **Orden**: Despliega infraestructura primero, luego microservicios
5. **Wait**: Espera a que Eureka y Config Server estén listos antes de desplegar los servicios

---

## 🎯 Checklist de Entrega

- [ ] Minikube instalado y funcionando
- [ ] Todas las imágenes Docker construidas
- [ ] Manifiestos K8s generados
- [ ] Servicios desplegados en Minikube
- [ ] Pruebas unitarias implementadas (mínimo 5)
- [ ] Pruebas de integración implementadas (mínimo 5)
- [ ] Pruebas E2E implementadas (mínimo 5)
- [ ] Pruebas de rendimiento con Locust
- [ ] GitHub Actions workflows configurados (DEV, STAGE, PROD)
- [ ] Screenshots de:
  - [ ] Workflows ejecutándose
  - [ ] Pods corriendo en Minikube
  - [ ] Servicios respondiendo
  - [ ] Resultados de pruebas
  - [ ] Reporte de Locust
- [ ] Documentación completa

---

## 📚 Referencias

- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Locust Docs](https://docs.locust.io/)
