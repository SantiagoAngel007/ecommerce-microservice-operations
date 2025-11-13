# Metodología Ágil y Estrategia de Branching

## 1. Metodología Ágil: Kanban

Se implementará **Kanban** como metodología ágil para este proyecto por las siguientes razones:

Para este proyecto específico, Kanban es más apropiado porque: permite adaptarse rápidamente a cambios en los requisitos de infraestructura y despliegue, facilita la identificación inmediata de cuellos de botella en el pipeline CI/CD, y proporciona mayor flexibilidad para gestionar tareas paralelas de diferentes microservicios sin la rigidez de sprints cerrados. Además, en un contexto de DevOps, donde la integración y el despliegue continuo son fundamentales, Kanban se alinea mejor con el flujo dinámico del trabajo.

## 2. Estrategia de Branching: GitHub Flow

Se adoptará **GitHub Flow** como estrategia de branching debido a su simplicidad y efectividad en equipos reducidos:

Se eligió GitHub Flow sobre GitFlow porque: reduce la complejidad operacional al eliminar la rama `develop` permanente, acelera el tiempo de integración con merges directos a main tras validación, es más adecuado para equipos pequeños donde la simplicidad mejora la colaboración, y se alinea perfectamente con la estrategia de despliegue continuo que se implementará mediante Kubernetes en Docker Desktop.

La estructura de ramificación será la siguiente:
- `main`: rama de producción, protegida, solo recibe merges validados
- `feature/*`: ramas de características específicas, creadas desde main, ejemplo: `feature/circuit-breaker`, `feature/terraform-infrastructure`
- `bugfix/*`: ramas para correcciones críticas, ejemplo: `bugfix/security-patch`

## 3. Sistema de Gestión de Proyectos: Trello

Se utilizará **Trello** como herramienta de gestión de proyectos ágil por las siguientes razones:

Se seleccionó Trello porque: su interfaz es intuitiva y fácil de usar sin curva de aprendizaje pronunciada, ofrece visualización inmediata del estado de todas las tareas, permite agregar descrippciones detalladas, checklists y adjuntos a cada tarjeta, y su modelo de precios gratuito es suficiente para este proyecto. Además, existe integración nativa con GitHub mediante Power-Ups, lo que permite sincronizar automáticamente el estado de las tareas con los pull requests.

## 4. Documentación de Historias de Usuario

Las historias de usuario están documentadas en Trello con el siguiente formato estándar:

**Estructura de cada Historia de Usuario:**
- Título descriptivo y conciso
- Descripción: narrativa clara de lo que se necesita
- Criterios de aceptación: condiciones específicas que deben cumplirse
- Tareas: subtareas desglosadas (checklist)
- Labels: categorización (infraestructura, backend, testing, etc.)
- Estimación: puntos de historia (1, 2, 3, 5, 8)

**Ejemplo de Historia de Usuario:**

Título: "Configurar Terraform modular para VPC y subredes"

Descripción: Como DevOps, necesito configurar la infraestructura base en Terraform de forma modular para poder gestionar múltiples ambientes (dev, stage, prod) de manera escalable y reutilizable.

Criterios de aceptación:
- Se ha creado la estructura modular de Terraform con carpetas por componente (vpc, compute, database, networking)
- Se han definido variables de entrada (inputs) y salidas (outputs) en cada módulo
- Se ha configurado backend remoto en S3 para el estado de Terraform
- La infraestructura puede desplegarse en ambientes dev, stage, prod sin duplicación de código
- Se ha documentado la estructura y el proceso de uso en README
- Se ha validado con `terraform plan` sin errores

Tareas:
- [ ] Crear estructura de directorios modular
- [ ] Implementar módulo VPC
- [ ] Implementar módulo subredes
- [ ] Configurar backend remoto S3
- [ ] Crear variables.tf y outputs.tf
- [ ] Documentar estructura
- [ ] Validar con terraform validate

## 5. Iteraciones Planificadas

Se realizarán **2 iteraciones completas** de una duración de 2 semanas cada una:

**Iteración 1 (Semanas 1-2): Fundamentos e Infraestructura**
- Configuración del repositorio y ramificación Git
- Implementación de Terraform modular para infraestructura base
- Dockerización de todos los microservicios (user-service, product-service, order-service, payment-service, shipping-service, favourite-service)
- Configuración inicial de CI/CD con GitHub Actions y Jenkins


**Iteración 2 (Semanas 3-4): Observabilidad, Seguridad y Testing Avanzado**
- Implementación de patrones de resiliencia (Circuit Breaker con Resilience4j)
- Implementación de Feature Toggle
- Configuración de stack observabilidad (Prometheus, Grafana, ELK)
- Implementación de pruebas de integración y E2E
- Configuración de seguridad (RBAC, TLS, gestión de secretos)
- Generación automática de Release Notes

**Métricas de Evaluación:**
- Velocity: promedio de puntos completados por iteración
- Defect Rate: porcentaje de tareas completadas sin defectos
- On-Time Delivery: porcentaje de tareas terminadas dentro del plazo estimado

---
