# Reporte de Patrones de Diseño Implementados

Este documento describe los patrones de diseño implementados en el proyecto, su propósito y los beneficios que aportan.

---

## 1. Microservicios
**Propósito:** Dividir la aplicación en servicios independientes, cada uno con su propia lógica y base de datos.
**Beneficios:**
- Escalabilidad independiente
- Despliegue y mantenimiento más sencillo
- Aislamiento de fallos

## 2. Controller-Service-Repository (MVC extendido)
**Propósito:** Separar la lógica de presentación, negocio y acceso a datos.
**Beneficios:**
- Código más organizado y mantenible
- Facilita pruebas unitarias y de integración

## 3. DTO (Data Transfer Object)
**Propósito:** Transferir datos entre capas y servicios sin exponer las entidades de dominio.
**Beneficios:**
- Desacopla la lógica interna de la API externa
- Facilita la validación y transformación de datos

## 4. Builder
**Propósito:** Facilitar la creación de objetos complejos de manera legible y flexible.
**Beneficios:**
- Código más limpio y menos propenso a errores
- Facilita la construcción de objetos inmutables

## 5. Singleton (Spring Beans)
**Propósito:** Garantizar una única instancia de cada servicio, repositorio o componente.
**Beneficios:**
- Eficiencia en el uso de recursos
- Facilita la gestión de dependencias

## 6. Event Listener
**Propósito:** Ejecutar lógica en respuesta a eventos del ciclo de vida de la aplicación.
**Beneficios:**
- Desacopla la lógica de inicialización y eventos
- Facilita la extensión de funcionalidades

## 7. Excepción/Respuesta Unificada
**Propósito:** Centralizar la estructura y manejo de errores.
**Beneficios:**
- Respuestas de error consistentes
- Mejor experiencia para el consumidor de la API

## 8. Mapper (Mapping Helper)
**Propósito:** Convertir entre entidades y DTOs de forma centralizada.
**Beneficios:**
- Reduce duplicidad de código
- Facilita el mantenimiento y la evolución del modelo

## 9. Inyección de Dependencias
**Propósito:** Gestionar las dependencias entre componentes automáticamente.
**Beneficios:**
- Facilita el testeo y el desacoplamiento
- Promueve buenas prácticas de diseño

## 10. Circuit Breaker (Resilience4j + Feign)
**Propósito:** Proteger los servicios ante fallos en cascada y mejorar la resiliencia.
**Beneficios:**
- Evita sobrecargar servicios caídos
- Responde rápidamente ante fallos
- Mejora la estabilidad general del sistema

---

Cada patrón contribuye a la robustez, mantenibilidad y escalabilidad del sistema, siguiendo buenas prácticas de arquitectura moderna.
