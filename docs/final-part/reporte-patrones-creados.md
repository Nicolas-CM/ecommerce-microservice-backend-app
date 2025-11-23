# Reporte de Patrones de Diseño Implementados o Mejorados

Este documento describe los patrones de diseño implementados en el proyecto, su propósito y los beneficios que aportan.

---

## 🛡️ Patrón de Resiliencia: Circuit Breaker

**Implementación realizada en el microservicio — `ProductClientService`**

### ✔️ Descripción del patrón

El patrón **Circuit Breaker** evita que un servicio siga llamando a otro servicio externo cuando este último está fallando de forma continua.
Funciona igual que un fusible eléctrico:

* **Si detecta muchas fallas → abre el circuito**
* **Mientras está abierto → bloquea las llamadas antes de que ocurran**
* **Después de un tiempo → intenta un estado *half-open*** para verificar si el servicio ya se recuperó

Este patrón protege al sistema, evita cascadas de fallos y mejora la **resiliencia** en arquitecturas de microservicios.

---

### ✔️ Implementación realizada

Se implementó un Circuit Breaker mediante el **fallback de Feign**, que activa una clase de respaldo cuando el microservicio `PRODUCT-SERVICE` no responde o está caído.

### **Clase:** `ProductClientService`

#### Fragmento relevante:

```java
@FeignClient(
    name = "PRODUCT-SERVICE",
    contextId = "productClientService",
    path = "/product-service/api/products",
    fallback = ProductClientService.ProductClientFallback.class
)
public interface ProductClientService {
```

### **Fallback utilizado:**

```java
@Component
class ProductClientFallback implements ProductClientService {

    @Override
    public ResponseEntity<ProductProductServiceCollectionDtoResponse> findAll() {
        throw new ResponseStatusException(
            HttpStatus.SERVICE_UNAVAILABLE,
            "PRODUCT-SERVICE no disponible (circuit breaker activado)"
        );
    }
    
    // ...se aplica el mismo fallback para findById, save, update y delete
}
```

Este fallback se ejecuta automáticamente cuando:

* El servicio remoto **no responde**
* El **timeout** expira
* El servicio está **caído**
* No se puede establecer comunicación con el servicio externo

---

### ✔️ Propósito del patrón en este proyecto

Garantizar la **resiliencia entre microservicios**, evitando que fallas en `PRODUCT-SERVICE` afecten al resto de la aplicación.

Este patrón es clave en un sistema de comercio electrónico, donde un fallo en un microservicio puede impactar procesos críticos como:

* Catálogos
* Órdenes
* Pagos
* Inventario

---

### ✔️ Beneficios obtenidos

* Aísla fallas de un microservicio para que no derriben todo el sistema
* Reduce la latencia cuando un servicio está caído (evita timeouts repetidos)
* Mejora la tolerancia a fallos
* Permite mostrar errores controlados
* Añade puntos de observabilidad al monitorear las activaciones del fallback

---

## 🧱 Patrón de Resiliencia: Bulkhead

**Implementación realizada en el microservicio — `proxy-client`**

### ✔️ Descripción del patrón

El patrón **Bulkhead** (Mamparo) aísla los recursos utilizados por diferentes partes de la aplicación para evitar que un fallo en una parte agote todos los recursos del sistema (como hilos de ejecución), afectando a otras funcionalidades.
Se inspira en los compartimentos estancos de los barcos:

* **Si un compartimento se inunda → el agua no pasa a los demás**
* **El barco sigue a flote → aunque una parte esté dañada**

En software, esto significa limitar el número de llamadas concurrentes que se pueden hacer a un servicio específico.

---

### ✔️ Implementación realizada

Se implementó utilizando **Resilience4j** en el `proxy-client` para proteger las llamadas hacia el `product-service`.

### **Configuración:** `application.yml`

Se definieron límites estrictos de concurrencia:

```yaml
resilience4j:
  bulkhead:
    instances:
      productServiceBulkhead:
        maxConcurrentCalls: 50  # Máximo 50 peticiones simultáneas
        maxWaitDuration: 100ms   # Tiempo máximo de espera en cola
```

### **Clase:** `ProductController`

Se aplicó la anotación `@Bulkhead` en los endpoints del controlador:

```java
@GetMapping
@Bulkhead(name = "productServiceBulkhead", fallbackMethod = "findAllFallback")
public ResponseEntity<ProductProductServiceCollectionDtoResponse> findAll() {
    log.info("** Proxy Client: Fetching all products with Bulkhead protection **");
    return ResponseEntity.ok(this.productClientService.findAll().getBody());
}

public ResponseEntity<ProductProductServiceCollectionDtoResponse> findAllFallback(Throwable t) {
    log.error("!! Bulkhead Full: No se pueden procesar más peticiones !!");
    return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
}
```

---

### ✔️ Propósito del patrón en este proyecto

Proteger al `proxy-client` de ser saturado por peticiones lentas o bloqueadas hacia el `product-service`. Si el servicio de productos se vuelve lento, el Bulkhead evitará que todas las conexiones del proxy se queden esperando, permitiendo que otras operaciones del proxy sigan funcionando.

---

### ✔️ Beneficios obtenidos

* **Aislamiento de fallos:** Un servicio lento no consume todos los recursos del sistema.
* **Estabilidad:** El sistema permanece operativo incluso bajo carga pesada en componentes específicos.
* **Fail Fast:** Con un `maxWaitDuration` bajo (10ms), el sistema rechaza rápidamente el exceso de tráfico en lugar de encolarlo indefinidamente.

![Diagrama Bulkhead](images/bulkhead.png)