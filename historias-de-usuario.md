1. Metodología Ágil y Estrategia de Branching (10%)

HU-01 – Implementación de metodología ágil

Como equipo de desarrollo
Quiero trabajar bajo una metodología ágil (Scrum o Kanban)
Para organizar el proyecto de manera iterativa y mejorar la entrega continua.

Criterios de aceptación

Given un proyecto en desarrollo
When se planifica el trabajo
Then debe existir un tablero ágil con tareas organizadas en To Do, Doing, Done.

Se deben documentar sprints o ciclos.

Tareas

Configurar tablero en Jira / Trello / GitHub Projects.

Crear backlog inicial.

Definir ceremonias: sprint planning, daily, sprint review, retrospectiva.

Documentar al menos 2 iteraciones completas.

HU-02 – Estrategia de branching

Como desarrollador
Quiero una estrategia clara de branching (GitFlow o GitHub Flow)
Para organizar el código y evitar conflictos en el repositorio.

Criterios de aceptación

Documentación visible en el repo (/docs/branching.md).

Flujo debe incluir ramas: main, develop, feature/*, release/*, hotfix/*.

Deben existir ejemplos de PR y merges.

Tareas

Crear archivo de documentación.

Configurar reglas de protección de ramas.

Definir políticas de merge.

HU-03 – Historias de usuario y criterios de aceptación

Como Product Owner
Quiero documentar las historias de usuario del proyecto
Para garantizar que el desarrollo tenga claridad y trazabilidad.

Criterios de aceptación

Cada historia debe incluir: descripción, criterios Given/When/Then, tareas técnicas.

Historias asociadas a un sprint.

2. Infraestructura como Código con Terraform (20%)
HU-04 – Infraestructura con Terraform

Como ingeniero DevOps
Quiero definir toda la infraestructura usando Terraform
Para poder crear ambientes reproducibles y controlados.

Criterios de aceptación

Estructura modular (/modules/*).

Despliegue para ambientes: dev, stage, prod.

Estado remoto configurado (S3, GCS, Terraform Cloud).

Tareas

Crear módulos: network, security, compute, storage.

Generar archivos main.tf, variables.tf, outputs.tf.

Configurar backend remoto.

Probar despliegue en al menos un ambiente.

HU-05 – Documentación de arquitectura

Como equipo técnico
Quiero diagramas de infraestructura
Para entender visualmente la arquitectura implementada.

Criterios de aceptación

Diagrama debe incluir: redes, VMs/containers, balanceadores, seguridad.

Debe quedar almacenado en /docs/infra.

3. Patrones de Diseño (10%)
HU-06 – Identificación de patrones existentes

Como arquitecto de software
Quiero identificar los patrones ya presentes en el sistema
Para mejorar la arquitectura general del proyecto.

Criterios de aceptación

Documento donde se describan patrones encontrados.

Debe incluir propósito, ventajas, desventajas.

HU-07 – Implementación de patrones adicionales

Como desarrollador
Quiero agregar al menos 3 patrones de diseño
Para mejorar resiliencia, configuración y escalabilidad.

Criterios de aceptación

Debe existir al menos:

1 patrón de resiliencia → Circuit Breaker / Bulkhead

1 patrón de configuración → External Config / Feature Toggle

1 patrón adicional

Documentación del código nuevo.

4. CI/CD Avanzado (15%)
HU-08 – Pipeline completo de CI/CD

Como ingeniero DevOps
Quiero crear pipelines de CI/CD
Para automatizar construcción, pruebas y despliegues.

Criterios de aceptación

Pipeline con etapas: build, test, scan, deploy.

Ambientes independientes: dev → stage → prod.

Versionado semántico automático.

HU-09 – Integración de SonarQube y Trivy

Como desarrollador
Quiero validar calidad y seguridad del código
Para prevenir vulnerabilidades y errores.

Criterios de aceptación

Análisis SonarQube ejecutándose en CI.

Escaneo de contenedores con Trivy.

Reportes generados automáticamente.

HU-10 – Notificaciones y aprobaciones

Como equipo de desarrollo
Quiero tener alertas por fallos y aprobaciones manuales
Para garantizar seguridad en despliegues.

Criterios de aceptación

Notificaciones por email o Slack.

Gate de aprobación para producción.

5. Pruebas Completas (15%)
HU-11 – Pruebas unitarias

Como desarrollador
Quiero pruebas unitarias en los microservicios
Para validar la lógica individual.

Criterios de aceptación

Cobertura mínima (50–70%).

Pruebas ejecutadas en pipeline CI.

HU-12 – Pruebas de integración

Como ingeniero de calidad (QA)
Quiero pruebas entre servicios
Para garantizar la correcta comunicación.

HU-13 – Pruebas E2E

Como usuario final
Quiero validar flujos completos
Para asegurar que todo funciona correctamente.

HU-14 – Pruebas de rendimiento, estrés y seguridad

Incluye:

Locust

OWASP ZAP

Criterios de aceptación

Reportes generados.

Scripts almacenados en /tests.

6. Change Management y Release Notes (5%)
HU-15 – Gestión de cambios

Como equipo DevOps
Quiero un proceso formal de control de cambios
Para evitar despliegues no autorizados.

HU-16 – Release notes automáticos

Como Product Owner
Quiero que los releases se generen solos
Para tener trazabilidad clara.

7. Observabilidad y Monitoreo (10%)
HU-17 – Stack Prometheus + Grafana

Como operador del sistema
Quiero monitoreo técnico
Para visualizar comportamiento del sistema.

HU-18 – ELK Stack

Como equipo DevOps
Quiero un sistema centralizado de logs
Para investigar errores y auditorías.

HU-19 – Tracing distribuido

Como ingeniero
Quiero Jaeger o Zipkin
Para medir latencias entre microservicios.

HU-20 – Alertas y health checks

Como operador
Quiero alertas y probes
Para reaccionar rápidamente a incidentes.

8. Seguridad (5%)
HU-21 – Escaneo continuo de vulnerabilidades

Como equipo de seguridad
Quiero detectar riesgos
Para proteger el sistema.

HU-22 – Gestión de secretos y TLS

Incluye:

Vault / SSM / Secret Manager

Certificados HTTPS

9. Documentación y Presentación (10%)
HU-23 – Documentación completa

Como cualquier miembro del equipo
Quiero documentación detallada
Para facilitar mantenimiento y nuevos ingresos.

HU-24 – Video y presentación final

Como equipo del proyecto
Quiero mostrar el funcionamiento
Para demostrar el cumplimiento del taller.