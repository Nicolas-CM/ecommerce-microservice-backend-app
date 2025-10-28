Collecting workspace information# Guía de Despliegue Completo del Proyecto E-commerce

Voy a ayudarte a desplegar todo el sistema correctamente y verificar el seguimiento con Zipkin. Basándome en la documentación y los archivos del proyecto, aquí está la guía paso a paso:

## 📋 Pre-requisitos

Asegúrate de tener instalado:
- Docker & Docker Compose
- Java 11
- Maven

## 🚀 Paso 1: Construcción de los Servicios

Primero, construye todos los microservicios:

```bash
# Desde la raíz del proyecto
./mvnw clean package -DskipTests
```

O si prefieres con tests:

```bash
./mvnw clean package
```

## 🐳 Paso 2: Despliegue de Servicios Core

Según la documentación, necesitas levantar primero los servicios de infraestructura. Veo que tienes archivos separados, pero según compose.yml, todo está en un solo archivo.

### Opción A: Usando el compose.yml principal

```bash
# Levanta SOLO los servicios core primero
docker-compose up -d service-discovery-container cloud-config-container zipkin-container
```

### Opción B: Si tienes core.yml separado (según la guía)

```bash
docker-compose -f core.yml up -d
```

## 🔍 Paso 3: Verificar que los Servicios Core estén Listos

**Para Service Discovery (Eureka):**

```bash
# Ver logs
docker logs service-discovery-container

# Busca este mensaje:
# "Finished initializing remote region registries. All known remote regions: []"
```

O verifica en el navegador:
```
http://localhost:8761/eureka
```

**Para Cloud Config:**

```bash
docker logs cloud-config-container

# El servicio debe estar escuchando en puerto 9296
```

**Para Zipkin:**

```
http://localhost:9411/zipkin/
```

## 🎯 Paso 4: Levantar API Gateway

Una vez que Eureka y Config Server estén listos:

```bash
docker-compose up -d api-gateway-container
```

Verifica los logs:

```bash
docker logs -f api-gateway-container

# Busca:
# "Response 200 OK" en llamadas a Eureka
```

Verifica que esté registrado en Eureka:
```
http://localhost:8761
```

## 🏪 Paso 5: Levantar los Microservicios de Negocio

```bash
docker-compose up -d user-service-container product-service-container order-service-container payment-service-container shipping-service-container favourite-service-container proxy-client-container
```

## ✅ Paso 6: Verificar el Estado de Todos los Servicios

### Verificar en Eureka Dashboard

```
http://localhost:8761
```

Deberías ver todos estos servicios registrados:
- API-GATEWAY
- PROXY-CLIENT
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

### Verificar Health de todos los servicios

```bash
curl -k http://localhost:8080/actuator/health | jq
```

## 🧪 Paso 7: Probar los Endpoints

### A través del API Gateway (Puerto 8080)

```bash
# Productos
curl http://localhost:8080/app/api/products | jq

# Usuarios
curl http://localhost:8080/app/api/users | jq
```

### Directamente a cada servicio

````bash
# User Service
curl http://localhost:8700/user-service/api/users | jq

# Product Service
curl http://localhost:8500/product-service/api/products | jq

# Order Service
curl http://localhost:8300/order-service/api/orders | jq

# Payment Service
curl http://localhost:8400/payment-service/api/payments | jq

# Shipping Service
curl http://localhost:8600/shipping-service/api/shippings | jq

# Favourite Service
curl http://localhost:8800/favourite-service/api/favourites | jq
````

### Crear un Usuario (POST)

Crea un archivo `create-user.json`:

```json
{
    "firstName": "Alejandro",
    "lastName": "Cordoba",
    "imageUrl": "https://example.com/avatar.jpg",
    "email": "alejandro.cordoba@example.com",
    "phone": "+57 300 1234567",
    "addressDtos": [
        {
            "fullAddress": "Calle 18 #122-135",
            "postalCode": "760001",
            "city": "Cali"
        }
    ],
    "credentialDto": {
        "username": "acordoba",
        "password": "securePassword123",
        "roleBasedAuthority": "ROLE_USER",
        "isEnabled": true,
        "isAccountNonExpired": true,
        "isAccountNonLocked": true,
        "isCredentialsNonExpired": true
    }
}
```

Ejecuta:

```bash
curl -X POST http://localhost:8700/user-service/api/users \
  -H "Content-Type: application/json" \
  -d @create-user.json | jq
```

## 🔍 Paso 8: Verificar Trazabilidad en Zipkin

1. **Accede a Zipkin:**
   ```
   http://localhost:9411/zipkin/
   ```

2. **Genera tráfico entre servicios:**

```bash
# Hacer varias peticiones para generar trazas
for i in {1..5}; do
  curl http://localhost:8080/app/api/products
  curl http://localhost:8080/app/api/users
  sleep 1
done
```

3. **En la UI de Zipkin:**
   - Haz clic en "Find Traces"
   - Selecciona un servicio (ej: API-GATEWAY)
   - Verás el flujo completo de la petición a través de los microservicios

4. **Visualiza las dependencias:**
   - Clic en "Dependencies"
   - Selecciona el rango de tiempo
   - Verás el diagrama de dependencias como el de tu imagen

## 📊 Paso 9: Monitoreo con Actuator

```bash
# Health de todos los servicios
curl http://localhost:8080/actuator/health | jq

# Métricas de Prometheus
curl http://localhost:8080/actuator/prometheus

# Info del servicio
curl http://localhost:8080/actuator/info | jq
```

## 🛑 Detener Todo

```bash
docker-compose down --remove-orphans
```

## 🔧 Troubleshooting

### Si un servicio no se registra en Eureka:

```bash
# Ver logs del servicio
docker logs <nombre-contenedor>

# Reiniciar el servicio
docker-compose restart <nombre-servicio>
```

### Si Zipkin no muestra trazas:

1. Verifica que la URL de Zipkin esté correcta en las variables de entorno
2. Comprueba los logs: `docker logs zipkin-container`
3. Asegúrate de que `SPRING_ZIPKIN_BASE-URL=http://zipkin:9411` esté configurado en todos los servicios

### Verificar conectividad entre contenedores:

```bash
# Desde dentro de un contenedor
docker exec -it api-gateway-container ping zipkin
docker exec -it user-service-container ping service-discovery-container
```

## 📝 Notas Importantes

- Los servicios pueden tardar 30-60 segundos en registrarse completamente en Eureka
- Espera a ver los logs de registro exitoso antes de probar los endpoints
- El API Gateway actúa como punto de entrada único (puerto 8080)
- Zipkin solo mostrará trazas después de que hayas hecho peticiones HTTP

¡Ahora deberías tener todo el sistema funcionando y rastreando peticiones en Zipkin! 🎉