[🏠 Volver al README](../../README.md#patrones-de-diseño-implementados)

---

# Reporte de Patrones de Diseño

Este documento identifica y describe los principales patrones de diseño presentes en el proyecto **ecommerce-microservice-backend-app**.

---

## 1. Patrón de Microservicios
- El sistema está compuesto por múltiples servicios independientes (user-service, order-service, payment-service, etc.), cada uno con su propia lógica, base de datos y despliegue.

## 2. Controller-Service-Repository (MVC extendido)
- **Controller/Resource**: Manejan las peticiones HTTP y delegan la lógica.
- **Service**: Implementan la lógica de negocio.
- **Repository**: Acceso a datos, generalmente usando Spring Data JPA.

## 3. DTO (Data Transfer Object)
- Clases como `OrderDto`, `FavouriteDto`, `VerificationTokenDto` se usan para transferir datos entre capas y servicios, desacoplando la entidad de dominio de la representación externa.

## 4. Builder
- Uso de Lombok `@Builder` en DTOs y entidades para facilitar la creación de objetos complejos de manera fluida y legible.

## 5. Singleton (Spring Beans)
- Las clases anotadas con `@Service`, `@Component`, `@Repository` son singletons gestionados por el contenedor de Spring.

## 6. Event Listener
- Uso de `@EventListener` en clases como `DefaultUserConfig` para reaccionar a eventos del ciclo de vida de la aplicación.

## 7. Patrón de Excepción/Respuesta Unificada
- Clases como `ExceptionMsg` centralizan la estructura de los mensajes de error, siguiendo el patrón de objeto de error.

## 8. Mapping Helper (Mapper)
- Clases como `UserMappingHelper`, `OrderMappingHelper` implementan el patrón Mapper para convertir entre entidades y DTOs.

## 9. Inyección de Dependencias
- Uso extensivo de la inyección de dependencias de Spring (`@Autowired`, `@RequiredArgsConstructor`).

---

### Resumen
El proyecto implementa patrones clásicos de aplicaciones empresariales Java/Spring: Microservicios, Controller-Service-Repository, DTO, Builder, Singleton (Spring Beans), Event Listener, Mapper, y manejo centralizado de excepciones. Además, sigue buenas prácticas de arquitectura limpia y desacoplamiento.

[🏠 Volver al README](../../README.md#patrones-de-diseño-implementados)
