## Regresar a [Parte inicial](initial-part.md).

## Regresar al [Readme](../../README.md#guía-de-despliegue-en-minikube-inicial).

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
- ✅ gcloud CLI configurado con acceso al proyecto GCP

---

## ☁️ Despliegue en GCP (Cloud Run con Terraform)

> Usa esta sección cuando quieras desplegar los microservicios en Google Cloud Run mediante los módulos Terraform que viven en `infra/terraform/gcp`. El prerequisito es haber creado previamente el Artifact Registry `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services` (el módulo `artifact_registry` ya lo crea) y haber iniciado sesión con `gcloud auth login`.

### 0.1 Autenticación y proyecto

```powershell
gcloud auth login
gcloud config set project eco-microservices-dev
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### 0.2 Compilar y publicar imágenes `v0.1.0`

Cada servicio debe generar un JAR, construir una imagen y publicarla en el registry antes de correr `terraform apply`. Ejecuta los siguientes pasos desde la raíz del repo, reemplazando `<service-dir>` y `<image-name>` con los valores de la tabla:

| Directorio | Imagen |
|------------|--------|
| `api-gateway` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/api-gateway:v0.1.0` |
| `cloud-config` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/cloud-config:v0.1.0` |
| `favourite-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/favourite-service:v0.1.0` |
| `user-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/user-service:v0.1.0` |
| `order-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/order-service:v0.1.0` |
| `product-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/product-service:v0.1.0` |
| `payment-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/payment-service:v0.1.0` |
| `shipping-service` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/shipping-service:v0.1.0` |
| `service-discovery` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/service-discovery:v0.1.0` |
| `proxy-client` | `us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services/proxy-client:v0.1.0` |

```powershell
Set-Location C:\Users\CTecn\Desktop\ecommerce-microservice-backend-app\<service-dir>
mvn -DskipTests package
docker build -t <image-name> .
docker push <image-name>
```

> Sugerencia: repite los comandos anteriores por cada servicio. Si ya existen etiquetas diferentes en el registry, también puedes actualizar `terraform.tfvars` para apuntar a esas imágenes en lugar de `v0.1.0`.

Verifica las imágenes publicadas con:

```powershell
gcloud artifacts docker images list us-central1-docker.pkg.dev/eco-microservices-dev/eco-dev-services
```

### 0.3 Ejecutar Terraform en `dev`

```powershell
Set-Location C:\Users\CTecn\Desktop\ecommerce-microservice-backend-app\infra\terraform\gcp\environments\dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

Si el `apply` falla con `Image ... not found`, regresa a la fase 0.2 y asegúrate de publicar la imagen correspondiente. Una vez creados los servicios en Cloud Run puedes revisar sus endpoints y permisos desde la consola de GCP.

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
kubectl delete -f k8s/base/favourite-service.yaml -n ecommer
```

#### Cambios en código (REINICIO)

- Recompilar (ya tienes V13__update_admin_password.sql)

cd user-service
mvnw.cmd clean package -DskipTests
cd ..

- Apuntar a Minikube Docker

@FOR /f "tokens=*" %i IN ('minikube -p minikube docker-env --shell cmd') DO @%i

- Reconstruir imagen
docker build -t user-service:latest ./user-service

- Eliminar pod para forzar BD nueva (importante para V13)
kubectl delete pod -n ecommerce -l app=user-service

- Esperar 20 segundos
timeout /t 20 /nobreak

- Verificar que V13 se ejecutó
kubectl logs -n ecommerce -l app=user-service | findstr "V13"

- Probar autenticación
curl -X POST http://localhost:8080/app/api/authenticate -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin\"}"

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

### 6.3 Probar API Gateway + Proxy-Client

#### Port-Forward del API Gateway
```powershell
kubectl port-forward -n ecommerce svc/api-gateway 8080:8080
```

#### Endpoints Públicos (Sin Autenticación)

```powershell
# 1. Verificar que el código está actualizado
curl http://localhost:8080/app/api/authenticate/status

# 2. Generar hash BCrypt de una contraseña
curl http://localhost:8080/app/api/authenticate/hash/admin
curl http://localhost:8080/app/api/authenticate/hash/testuser

# 3. Listar categorías
curl http://localhost:8080/app/api/categories

# 4. Listar productos
curl http://localhost:8080/app/api/products

# 5. Listar todos los usuarios (público)
curl http://localhost:8080/app/api/users
```

#### Verificar Hash BCrypt (POST)

**POST** `http://localhost:8080/app/api/authenticate/verify`

Body (raw JSON):
```json
{
  "password": "admin",
  "hash": "$2a$10$N.zmdr9k7uOCQaoXKRd/bOH3HwFx6djKE5Kz2bhAXrKPZ6gLWbwzq"
}
```

**Respuesta esperada:** `true` o `false`

---

#### Registro de Usuario (POST)

**POST** `http://localhost:8080/app/api/users`

Body (raw JSON):
```json
{
 "userId": "{{$randomInt}}",
 "firstName": "Alejandro",
 "lastName": "Cordoba",
 "imageUrl": "{{$randomUrl}}",
 "email": "{{$randomEmail}}",
 "addressDtos": [
    {
 "fullAddress": "123 Main St",
 "postalCode": "12345",
 "city": "New York"
 }
 ],
 "credential": {
 "username": "johndoe",
 "password": "securePassword123",
 "roleBasedAuthority": "ROLE_USER",
 "isEnabled": true,
 "isAccountNonExpired": true,
 "isAccountNonLocked": true,
 "isCredentialsNonExpired": true
 }
}
```

> ⚠️ **Importante**: Todos los campos booleanos de `credential` deben tener valor `true` para que el usuario pueda autenticarse correctamente.

---

#### Autenticación (POST)

**POST** `http://localhost:8080/app/api/authenticate`

Body (raw JSON) - Admin:
```json
{
  "username": "admin",
  "password": "admin"
}
```

Body (raw JSON) - TestUser:
```json
{
  "username": "testuser",
  "password": "testuser"
}
```

**Respuesta esperada:**
```json
{
  "username": "admin",
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...",
  "roles": ["ROLE_ADMIN"]
}
```

---

#### Endpoints Protegidos (Con JWT Token)

> 💡 **Nota**: Primero haz login y copia el token de la respuesta. Luego agrégalo en el Header `Authorization: Bearer TU_TOKEN`

**1. Crear un pedido**

**POST** `http://localhost:8080/app/api/orders`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
Content-Type: application/json
```

**1. Crear un carrito**

**POST** `http://localhost:8080/app/api/carts`

Body (raw JSON):
```json
{
  "userId": 1
}
```

**Respuesta esperada:** CartDto con `cartId` generado (ej. 1).

---

**2. Crear una orden con el carrito**

**POST** `http://localhost:8080/app/api/orders`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
Content-Type: application/json
```

Body (raw JSON):
```json
{
  "orderDate": "04-11-2025__20:00:00:000000",
  "orderDesc": "Pedido de prueba",
  "orderFee": 25.99,
  "cart": {
    "cartId": 1
  }
}
```

**Respuesta esperada:** OrderDto con `orderId` generado (ej. 1).

> ⚠️ **Importante**: Antes de crear la orden, verifica que el `cartId` existe ejecutando GET `http://localhost:8080/app/api/carts` para listar todos los carritos. Si no existe, crea uno primero con POST `/app/api/carts`.

---

**3. Agregar productos a la orden (OrderItem)**

**POST** `http://localhost:8080/app/api/shippings`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
Content-Type: application/json
```

Body (raw JSON):
```json
{
  "productId": 1,
  "orderId": 5,
  "orderedQuantity": 2
}
```

**Respuesta esperada:** OrderItemDto confirmando la adición.

**GET** `http://localhost:8080/app/api/orders/user/1`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
```

---

**3. Agregar a favoritos**

**POST** `http://localhost:8080/app/api/favourites`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
Content-Type: application/json
```

Body (raw JSON):
```json
{
"userId": 1,
"productId": 1,
"likeDate": "04-11-2025__20:00:00:000000"
}
```

---

**4. Ver mis favoritos**

**GET** `http://localhost:8080/app/api/favourites/user/1`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
```

---

**5. Listar todos los usuarios**

**GET** `http://localhost:8080/app/api/users`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
```

**Respuesta esperada:**
```json
[
  {
    "userId": 1,
    "firstName": "Admin",
    "lastName": "User",
    "imageUrl": null,
    "email": "admin@ecommerce.com",
    "phone": "+1234567890",
    "credential": {
      "credentialId": 1,
      "username": "admin",
      "password": "$2a$10$...",
      "roleBasedAuthority": "ROLE_ADMIN",
      "isEnabled": true,
      "isAccountNonExpired": true,
      "isAccountNonLocked": true,
      "isCredentialsNonExpired": true
    }
  }
]
```

---

**6. Ver un usuario específico por ID**

**GET** `http://localhost:8080/app/api/users/1`

Headers:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTczMDc1...
```

POST http://localhost:8080/app/api/payments

{
  "isPayed": false,
  "paymentStatus": "NOT_STARTED",
  "order": {
    "orderId": 1
  }
}

#### Verificar Eureka Registration

```powershell
# Ver servicios registrados en Eureka
kubectl port-forward -n ecommerce svc/service-discovery 8761:8761

# En navegador o curl
curl http://localhost:8761
```

**Servicios que deben aparecer:**
- API-GATEWAY
- PROXY-CLIENT
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

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

## ☁️ Despliegue en Google Cloud Run (Resumen y Troubleshooting)

## 1. Requisitos previos
- Cuenta de Google Cloud Platform (GCP) y proyecto creado.
- Google Cloud SDK (`gcloud`), Docker y Maven instalados.
- Acceso a Artifact Registry o Container Registry.
- Permisos de Owner o Editor en el proyecto de GCP.

## 2. Estructura y configuración
- Cada microservicio debe tener:
  - `application.yml` con:
    ```yaml
    server:
      port: ${PORT:808X}
    eureka:
      client:
        service-url:
          defaultZone: https://<URL_PUBLICA_EUREKA>/eureka
    ```
  - Dockerfile con:
    ```dockerfile
    EXPOSE 808X
    ENTRYPOINT ["java", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "<servicio>.jar"]
    ```
- Eureka (service-discovery) debe tener:
  - Dependencias `spring-cloud-starter-netflix-eureka-server` y `eureka-client` en el `pom.xml`.
  - Anotación `@EnableEurekaServer` en la clase principal.
  - Acceso público habilitado en Cloud Run (Permitir invocaciones no autenticadas).

## 3. Build y push de imágenes
Por cada microservicio:
```sh
cd <servicio>
mvn clean package
# Reemplaza <servicio> y <tag> según corresponda
docker build -t gcr.io/<proyecto>/<servicio>:<tag> .
docker push gcr.io/<proyecto>/<servicio>:<tag>
```

## 4. Despliegue con Terraform
Desde la carpeta de infraestructura:
```sh
cd infra/terraform/gcp/environments/dev
terraform apply -var-file="terraform.business.tfvars"
```

## 5. Troubleshooting y tips
- Si los servicios no arrancan, revisa los logs de Cloud Run.
- Si ves errores de Eureka, asegúrate de que la URL pública de Eureka sea accesible y el acceso no autenticado esté habilitado.
- Si la UI de Eureka no aparece, agrega la dependencia `eureka-client` y accede a `/eureka`.
- El acceso entre servicios en Cloud Run requiere que Eureka permita tráfico no autenticado.
- Para producción, considera usar VPC Connector y restringir el acceso.

## 6. Resumen de pasos realizados
- Corrección de puertos en Dockerfile y application.yml.
- Separación de despliegue en servicios base y de negocio.
- Configuración de Eureka y subida de imágenes a Container Registry.
- Habilitación de acceso público en Eureka.
- Agregado de dependencia `eureka-client` para la UI.
- Documentación de todo el proceso.

---

Para dudas o problemas, revisa los logs de Cloud Run y la documentación oficial de Google Cloud Run y Spring Cloud Netflix Eureka.

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

## 📚 Referencias

- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Locust Docs](https://docs.locust.io/)
