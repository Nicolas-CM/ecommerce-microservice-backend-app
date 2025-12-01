## [Volver al README](../../README.md#historias-de-usuario)

# Backlog del Proyecto E-commerce Microservices

Este documento presenta el backlog del proyecto estructurado según estándares de la industria, separando claramente las **Historias de Usuario** (valor de negocio) de las **Tareas Técnicas y Enablers** (infraestructura y soporte).

---

## 1. Product Backlog (Historias de Usuario)

### HU-01: Exploración de Productos
**Como** cliente de la tienda,
**Quiero** ver un listado de productos disponibles con sus precios e imágenes,
**Para** decidir qué artículos comprar.

**Criterios de Aceptación:**

- [ ] El sistema muestra una lista paginada de productos (endpoint `GET /product-service/products`).
- [ ] Cada tarjeta de producto incluye: nombre, precio, imagen y stock disponible.
- [ ] El tiempo de carga del listado es menor a 2 segundos.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-02: Detalle de Producto
**Como** cliente,
**Quiero** ver los detalles específicos de un producto,
**Para** conocer sus características antes de añadirlo al carrito.

**Criterios de Aceptación:**

- [ ] Al seleccionar un producto, se muestra su descripción completa, categoría y especificaciones.
- [ ] Se muestra un mensaje de error amigable si el producto no existe (404).
- [ ] Endpoint asociado: `GET /product-service/products/{id}`.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-03: Gestión de Favoritos
**Como** cliente registrado,
**Quiero** agregar productos a mi lista de favoritos,
**Para** guardarlos y comprarlos en el futuro sin tener que buscarlos de nuevo.

**Criterios de Aceptación:**

- [ ] El usuario puede agregar un producto a favoritos (endpoint `POST /favourite-service/add`).
- [ ] El usuario puede ver su lista de favoritos (endpoint `GET /favourite-service/list`).
- [ ] Si el usuario no está autenticado, se le redirige al login.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-04: Creación de Pedidos
**Como** cliente,
**Quiero** realizar un pedido con los productos seleccionados,
**Para** recibir los artículos en mi dirección.

**Criterios de Aceptación:**

- [ ] El sistema permite crear una orden con uno o más productos (endpoint `POST /order-service/orders`).
- [ ] Se valida que haya stock suficiente antes de confirmar la orden.
- [ ] La orden se crea con estado inicial "PENDING".
- [ ] Se genera un ID único de orden para seguimiento.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-05: Historial de Pedidos
**Como** cliente,
**Quiero** ver el estado de mis pedidos anteriores,
**Para** hacer seguimiento a mis compras y validar lo que he gastado.

**Criterios de Aceptación:**

- [ ] El usuario puede ver un listado de sus órdenes pasadas.
- [ ] Cada orden muestra su estado actual (Pending, Shipped, Delivered).
- [ ] Endpoint asociado: `GET /order-service/orders/user/{userId}`.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-06: Actualización de Perfil

**Como** cliente registrado,
**Quiero** actualizar mi información personal (nombre, dirección),
**Para** mantener mis datos de contacto y envío al día.

**Criterios de Aceptación:**

- [ ] El usuario puede modificar sus datos básicos (endpoint `PUT /user-service/users`).
- [ ] Se validan los datos de entrada (ej. formato de email).
- [ ] El usuario puede consultar su perfil actual (endpoint `GET /user-service/users/{userId}`).

**Prioridad:** Media (P2) | **Estimación:** S

### HU-07: Administración de Productos

**Como** administrador del sistema,
**Quiero** crear, actualizar y eliminar productos del catálogo,
**Para** mantener la oferta comercial actualizada.

**Criterios de Aceptación:**

- [ ] El administrador puede crear nuevos productos (endpoint `POST /product-service/products`).
- [ ] El administrador puede actualizar precio y stock (endpoint `PUT /product-service/products`).
- [ ] El administrador puede eliminar productos obsoletos (endpoint `DELETE /product-service/products/{id}`).
- [ ] Estas operaciones requieren rol de ADMIN.

**Prioridad:** Alta (P1) | **Estimación:** M

### HU-08: Gestión de Usuarios

**Como** administrador,
**Quiero** ver el listado de usuarios registrados y poder eliminarlos si es necesario,
**Para** moderar la plataforma y gestionar cuentas.

**Criterios de Aceptación:**

- [ ] El administrador puede listar todos los usuarios (endpoint `GET /user-service/users`).
- [ ] El administrador puede eliminar un usuario específico (endpoint `DELETE /user-service/users/{id}`).
- [ ] Se debe paginar el listado de usuarios si son muchos.

**Prioridad:** Media (P2) | **Estimación:** S

### HU-09: Gestión de Carrito de Compras

**Como** cliente,
**Quiero** agregar y gestionar productos en mi carrito de compras,
**Para** revisar mi selección antes de proceder al pago.

**Criterios de Aceptación:**

- [ ] El usuario puede ver su carrito (endpoint `GET /order-service/carts/{id}`).
- [ ] El usuario puede agregar o actualizar items en el carrito (endpoint `POST /order-service/carts` o `PUT`).
- [ ] El usuario puede vaciar o eliminar items del carrito (endpoint `DELETE /order-service/carts/{id}`).

**Prioridad:** Alta (P1) | **Estimación:** M

### HU-10: Procesamiento de Pagos

**Como** cliente,
**Quiero** pagar mi pedido de forma segura,
**Para** completar la compra.

**Criterios de Aceptación:**

- [ ] El usuario puede iniciar un pago para un pedido (endpoint `POST /payment-service/payments`).
- [ ] El sistema valida la información del pago.
- [ ] Se registra la transacción y se actualiza el estado del pedido.
- [ ] El usuario puede ver el detalle de un pago (endpoint `GET /payment-service/payments/{id}`).

**Prioridad:** Alta (P1) | **Estimación:** M

---

## 2. Technical Backlog (Enablers & Tasks)

*Tareas técnicas, configuración de infraestructura y pipelines necesarias para soportar el producto.*

### TASK-01: Infraestructura como Código (IaC) con Terraform

**Descripción:** Provisionar la infraestructura base necesaria para los ambientes de despliegue.

**Entregables:**

- Módulos Terraform creados para: Network, Compute, Storage.
- Archivos de estado (`terraform.tfstate`) gestionados remotamente (S3/Terraform Cloud).
- Ambientes `dev` y `stage` provisionados mediante scripts.

### TASK-02: Pipeline de CI/CD (Dev & Stage)

**Descripción:** Automatizar el ciclo de vida de construcción y despliegue de los microservicios.

**Entregables:**

- Workflow `.github/workflows/dev.yml`: Build Maven + Unit Tests (JUnit).
- Workflow `.github/workflows/stage.yml`: Build Docker Images + Deploy a Minikube.
- Publicación de artefactos de prueba (Surefire Reports).

### TASK-03: Implementación de Patrones de Resiliencia

**Descripción:** Mejorar la estabilidad del sistema ante fallos de servicios dependientes.

**Entregables:**

- Implementación de **Circuit Breaker** (Resilience4j) en llamadas entre servicios.
- Configuración de **Timeouts** y **Retries**.
- Pruebas de caos simulando la caída de un servicio dependiente.

### TASK-04: Observabilidad Centralizada

**Descripción:** Implementar un stack de monitoreo para visualizar el estado del sistema.

**Entregables:**

- **Prometheus** configurado para recolectar métricas de Spring Actuator.
- **Grafana** con dashboards operativos (CPU, Memoria, Latencia HTTP).
- **Zipkin/Jaeger** para tracing distribuido de peticiones.

### TASK-05: Pruebas E2E Automatizadas

**Descripción:** Validar los flujos críticos del negocio de punta a punta.

**Entregables:**

- Colección de Postman (`tests/e2e/ecommerce-e2e-tests.postman_collection.json`) actualizada.
- Ejecución automatizada con **Newman** en el pipeline de Stage.
- Reporte de resultados en formato JSON/HTML.

### TASK-06: Análisis de Calidad y Seguridad

**Descripción:** Asegurar la calidad del código y la seguridad de las imágenes Docker.

**Entregables:**

- Integración con **SonarQube** para análisis estático de código.
- Escaneo de vulnerabilidades en imágenes Docker usando **Trivy**.
- Quality Gates definidos en el pipeline (fallar si hay vulnerabilidades críticas).

### TASK-07: Documentación Técnica

**Descripción:** Generar documentación para facilitar el mantenimiento y onboarding.

**Entregables:**

- Diagramas de arquitectura (C4/UML) en `/docs`.
- `README.md` actualizado con instrucciones de despliegue.
- Documentación de APIs (Swagger/OpenAPI).

## [Volver al README](../../README.md#historias-de-usuario)