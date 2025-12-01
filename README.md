# 🚀 E-Commerce Microservices Platform - Operations

[![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)](https://microservices.io/)
[![Cloud](https://img.shields.io/badge/Cloud-GCP-4285F4?logo=google-cloud)](https://cloud.google.com/)
[![CI/CD](https://img.shields.io/badge/CI/CD-Jenkins-D24939?logo=jenkins)](https://www.jenkins.io/)
[![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Container](https://img.shields.io/badge/Container-Kubernetes-326CE5?logo=kubernetes)](https://kubernetes.io/)

Repositorio de infraestructura como código (IaC), pipelines CI/CD y manifiestos Kubernetes para la plataforma de e-commerce basada en microservicios desplegada en Google Cloud Platform.

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Arquitectura](#-arquitectura)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Estructura del Repositorio](#-estructura-del-repositorio)
- [Documentación Completa](#-documentación-completa)
- [Quick Start](#-quick-start)
- [Equipo](#-equipo)

---

## 📖 Descripción del Proyecto

Este repositorio contiene toda la infraestructura, configuración y automatización para el deployment de una plataforma de e-commerce basada en **arquitectura de microservicios** en Google Cloud Platform (GCP).

### 🎯 Componentes Principales

#### Infrastructure as Code (Terraform)
- ✅ VPC y networking en GCP
- ✅ GKE Autopilot clusters (DEV, STAGE, PROD)
- ✅ Artifact Registry para imágenes Docker
- ✅ Service Accounts y permisos IAM
- ✅ Backend remoto en Cloud Storage

#### CI/CD Pipelines (Jenkins)
- ✅ Pipeline automatizado DEV (triggered por webhooks)
- ✅ Pipeline STAGE con aprobaciones manuales
- ✅ Pipeline PROD con estrategia Blue-Green
- ✅ Escaneo de vulnerabilidades con Trivy
- ✅ Health checks y validaciones de cluster

#### Kubernetes Manifests
- ✅ Deployments para 11 microservicios
- ✅ Services (ClusterIP y LoadBalancer)
- ✅ ConfigMaps y Secrets
- ✅ HPA (Horizontal Pod Autoscaling)
- ✅ Network Policies
- ✅ Organizado por ambientes (dev/stage/prod)

---

## 🏗️ Arquitectura

### Vista General de Infraestructura

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Internet / Usuarios                             │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                            │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    GKE Autopilot Cluster                       │ │
│  │                                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────┐  │ │
│  │  │                    Namespace: dev                        │  │ │
│  │  │                                                           │  │ │
│  │  │   ┌──────────────┐         ┌──────────────┐            │  │ │
│  │  │   │ API Gateway  │◄────────│   Service    │            │  │ │
│  │  │   │  (Ingress)   │         │  Discovery   │            │  │ │
│  │  │   └──────┬───────┘         └──────────────┘            │  │ │
│  │  │          │                                               │  │ │
│  │  │          │  ┌────────────────────────────────────────┐ │  │ │
│  │  │          └─►│      Business Microservices Layer      │ │  │ │
│  │  │             │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │ │  │ │
│  │  │             │  │User  │ │Product││Order │ │Payment│  │ │  │ │
│  │  │             │  └──────┘ └──────┘ └──────┘ └──────┘  │ │  │ │
│  │  │             │  ┌──────┐ ┌──────┐                     │ │  │ │
│  │  │             │  │Shipping││Favour│                     │ │  │ │
│  │  │             │  └──────┘ └──────┘                     │ │  │ │
│  │  │             └────────────────────────────────────────┘ │  │ │
│  │  └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline                               │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Jenkins Server (VM e2-standard-2)                             │ │
│  │  • Webhook GitHub → Build → Test → Scan → Deploy              │ │
│  │  • DEV: Automático | STAGE: Manual | PROD: Blue-Green         │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tecnologías Utilizadas

### Infrastructure & Cloud
- **Google Cloud Platform (GCP)** - Cloud provider
- **Terraform** - Infrastructure as Code
- **Kubernetes (GKE Autopilot)** - Container orchestration
- **Docker** - Containerization
- **Artifact Registry** - Docker image storage

### CI/CD & Automation
- **Jenkins** - CI/CD pipeline automation
- **GitHub Webhooks** - Automated triggers
- **Trivy** - Container security scanning
- **Maven** - Build automation

### Monitoring & Observability
- **Zipkin** - Distributed tracing
- **Prometheus** - Metrics collection (configurado)
- **Grafana** - Visualization (configurado)
- **Spring Boot Actuator** - Application metrics

---

## 📁 Estructura del Repositorio

```
ecommerce-microservice-operations/
├── README.md                          # Este archivo
├── docs/
│   ├── 01-ARQUITECTURA.md            # Arquitectura detallada del sistema
│   ├── 02-GUIA-INSTALACION.md        # Guía de instalación y configuración
│   ├── 03-MANUAL-OPERACIONES.md      # Manual de operaciones diarias
│   ├── 04-COSTOS-INFRAESTRUCTURA.md  # Análisis de costos GCP
│   ├── 05-GUIA-SCREENSHOTS.md        # Guía para capturas profesionales
│   └── 06-VIDEO-DEMO.md              # Script y guía para video demo
│
├── terraform/
│   ├── environments/
│   │   ├── dev/                      # Ambiente de desarrollo
│   │   ├── stage/                    # Ambiente de staging
│   │   └── prod/                     # Ambiente de producción
│   ├── modules/
│   │   ├── gke/                      # Módulo GKE cluster
│   │   ├── vpc/                      # Módulo VPC networking
│   │   ├── artifact-registry/        # Módulo Artifact Registry
│   │   └── service-account/          # Módulo Service Accounts
│   └── backend-config/               # Backend remoto (GCS)
│
├── k8s/
│   ├── dev/                          # Manifiestos Kubernetes DEV
│   ├── stage/                        # Manifiestos Kubernetes STAGE
│   └── prod/                         # Manifiestos Kubernetes PROD
│
├── pipelines/
│   ├── Jenkinsfile.dev-gcp           # Pipeline DEV en GCP
│   ├── Jenkinsfile.stage-gcp         # Pipeline STAGE en GCP
│   ├── Jenkinsfile.prod-gcp          # Pipeline PROD en GCP
│   └── Jenkinsfile.infrastructure    # Pipeline de infraestructura
│
├── jenkins/
│   ├── Dockerfile                    # Jenkins personalizado
│   ├── docker-compose.yml            # Setup Jenkins local
│   └── plugins.txt                   # Lista de plugins Jenkins
│
├── setup/
│   ├── gcp-setup.sh                  # Script setup GCP
│   ├── jenkins-setup.sh              # Script setup Jenkins
│   └── kubectl-config.sh             # Script configuración kubectl
│
└── .github/
    └── workflows/
        └── validate-terraform.yml    # Validación Terraform en PR
```

---

## 📚 Documentación Completa

### 📖 Guías Principales

1. **[Arquitectura del Sistema](docs/01-ARQUITECTURA.md)**
   - Diagramas de arquitectura completos
   - Patrones de diseño implementados (Circuit Breaker, Feature Toggles)
   - Flujos de comunicación entre microservicios
   - Decisiones técnicas y trade-offs

2. **[Guía de Instalación](docs/02-GUIA-INSTALACION.md)**
   - Pre-requisitos detallados
   - Instalación de herramientas (gcloud, terraform, kubectl)
   - Configuración de GCP y credenciales
   - Deployment paso a paso para cada ambiente
   - Troubleshooting común durante instalación

3. **[Manual de Operaciones](docs/03-MANUAL-OPERACIONES.md)**
   - Operaciones diarias del sistema
   - Comandos útiles para troubleshooting
   - Procedimientos de backup y restore
   - Escalamiento de servicios
   - Monitoreo y alertas
   - Procedimientos de rollback

4. **[Análisis de Costos](docs/04-COSTOS-INFRAESTRUCTURA.md)**
   - Desglose detallado de costos por servicio GCP
   - Estimaciones mensuales por ambiente
   - Recomendaciones de optimización
   - Configuración de alertas de presupuesto
   - Comparación con alternativas (AWS, Azure)

5. **[Guía para Screenshots](docs/05-GUIA-SCREENSHOTS.md)**
   - 50+ capturas de pantalla requeridas
   - Comandos exactos para cada evidencia
   - Organización profesional de screenshots
   - Tips para capturas de calidad
   - Checklist de evidencias obligatorias

6. **[Video Demostrativo](docs/06-VIDEO-DEMO.md)**
   - Script completo del video (10-15 min)
   - Escenarios a demostrar
   - Herramientas de grabación recomendadas
   - Guía de edición y publicación
   - Checklist de contenido obligatorio

---

## 🚀 Quick Start

### Pre-requisitos

Antes de comenzar, asegúrate de tener instalado:

- ✅ **Google Cloud SDK** (`gcloud` CLI)
- ✅ **kubectl** v1.28+
- ✅ **Terraform** >= 1.5.0
- ✅ **Docker** >= 20.10
- ✅ **Git**
- ✅ Cuenta de GCP con Free Trial activo ($300 créditos)

### Deployment Rápido (Ambiente DEV)

```bash
# 1. Clonar repositorios
git clone https://github.com/SantiagoAngel007/ecommerce-microservice-operations.git
git clone https://github.com/SantiagoAngel007/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-operations

# 2. Configurar GCP
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 3. Crear Service Account
./setup/gcp-setup.sh

# 4. Crear infraestructura con Terraform
cd terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve

# 5. Configurar kubectl
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID

# 6. Desplegar aplicaciones en Kubernetes
cd ../../../k8s/dev
kubectl create namespace dev
kubectl apply -f . -R

# 7. Verificar deployment
kubectl get pods -n dev --watch
kubectl get svc -n dev
```

### Acceder a los Servicios

```bash
# Obtener IPs externas de los servicios
kubectl get svc -n dev

# URLs de acceso:
# - API Gateway: http://<EXTERNAL-IP>:8200
# - Service Discovery (Eureka): http://<EXTERNAL-IP>:8761
# - Zipkin Tracing: http://<EXTERNAL-IP>:9411
# - Config Server: http://<EXTERNAL-IP>:8888
```

---

## 🔧 Configuración de CI/CD

### Jenkins Setup

El servidor de Jenkins está desplegado en una VM de GCP (`e2-standard-2` en `us-central1-a`).

**Acceso:**
- URL: `http://34.123.43.189:8080`
- Credenciales: Ver [Guía de Instalación](docs/02-GUIA-INSTALACION.md#jenkins-setup)

**Pipelines Configurados:**

1. **ecommerce-dev-pipeline**
   - Trigger: Automático (webhook GitHub en push a rama `dev`)
   - Stages: Checkout → Build → Test → Scan → Docker Build → Push → Deploy DEV

2. **ecommerce-stage-pipeline**
   - Trigger: Manual
   - Stages: DEV + Integration Tests → Approval → Deploy STAGE

3. **ecommerce-prod-pipeline**
   - Trigger: Manual con aprobación
   - Estrategia: Blue-Green Deployment
   - Rollback automático si health checks fallan

### GitHub Webhooks

Webhooks configurados en el repositorio backend para trigger automático de pipelines:

```
Repository: ecommerce-microservice-backend-app
Webhooks:
  - DEV: http://34.123.43.189:8080/generic-webhook-trigger/invoke?token=dev-webhook-token-2024
  - STAGE: http://34.123.43.189:8080/generic-webhook-trigger/invoke?token=stage-webhook-token-2024
Event: push
Active: ✅
```

---

## 📊 Monitoreo y Observabilidad

### Herramientas Implementadas

| Herramienta | Puerto | Propósito | Estado |
|-------------|--------|-----------|--------|
| **Zipkin** | 9411 | Distributed tracing | ✅ Activo |
| **Prometheus** | 9090 | Métricas y alertas | ✅ Configurado |
| **Grafana** | 3000 | Visualización de métricas | ✅ Configurado |
| **Actuator** | /actuator | Health checks de servicios | ✅ Activo |

### Dashboards de Grafana

- **Cluster Overview**: CPU, memoria, pods por namespace
- **Application Metrics**: Request rate, latency, errors
- **JVM Metrics**: Heap usage, GC, threads
- **Business Metrics**: Orders/min, payments/min, usuarios activos

---

## 🧪 Testing

### Tests Implementados

```bash
# Tests E2E (Selenium)
cd ../ecommerce-microservice-backend-app/e2e-tests
mvn clean test

# Tests de Performance (Locust)
cd ../ecommerce-microservice-operations/performance-tests
locust -f locustfile-product-service.py --host=http://<API-GATEWAY-IP>:8200
```

**Cobertura de Tests:**
- 50+ tests E2E automatizados
- Tests de carga con Locust para todos los servicios
- Tests unitarios en cada microservicio (JUnit 5)

---

## 🛡️ Seguridad

### Implementaciones de Seguridad

- ✅ **Escaneo de vulnerabilidades**: Trivy en pipeline CI/CD
- ✅ **Secrets management**: Kubernetes Secrets
- ✅ **Network Policies**: Restricción de tráfico entre pods
- ✅ **Service Accounts**: Permisos mínimos necesarios (least privilege)
- ✅ **HTTPS**: Ingress con TLS (configurado para PROD)
- ✅ **RBAC**: Role-Based Access Control en Kubernetes

---

## 💰 Estimación de Costos

### Costos Mensuales Estimados (GCP)

| Ambiente | GKE Autopilot | Artifact Registry | Networking | Total/mes |
|----------|---------------|-------------------|------------|-----------|
| **DEV** | $45 | $5 | $10 | **$60** |
| **STAGE** | $120 | $10 | $20 | **$150** |
| **PROD** | $350 | $20 | $50 | **$420** |

**Total:** ~$630/mes

**Nota:** Ver [Análisis de Costos Detallado](docs/04-COSTOS-INFRAESTRUCTURA.md) para optimizaciones.

---

## 🤝 Contribución

Este proyecto es parte de un trabajo académico. Para contribuir:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Add: nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 👥 Equipo

**Proyecto Final - Ingeniería de Software V**

| Nombre | Rol | GitHub |
|--------|-----|--------|
| David Santiago Malte | DevOps Engineer & Backend Developer | [@dsmalte](https://github.com/dsmalte) |
| Santiago Ángel | Backend Developer & Architecture Designer | [@SantiagoAngel007](https://github.com/SantiagoAngel007) |

**Universidad:** Universidad EAFIT  
**Curso:** Ingeniería de Software V  
**Fecha:** Diciembre 2025

---

## 📄 Licencia

Este proyecto es desarrollado con fines académicos como parte del curso de Ingeniería de Software V.

---

## 🔗 Enlaces Importantes

- **[Repositorio Backend (Código Fuente)](https://github.com/SantiagoAngel007/ecommerce-microservice-backend-app)**
- **[Jenkins Server](http://34.123.43.189:8080)**
- **[Documentación Completa](./docs/)**
- **[Proyecto GCP](https://console.cloud.google.com/home/dashboard?project=ecommerce-microservices-478116)**

---

## 📞 Contacto

Para preguntas o soporte sobre este proyecto:

- **Email:** dsmalte2002@gmail.com
- **GitHub Issues:** [Reportar Issue](https://github.com/SantiagoAngel007/ecommerce-microservice-operations/issues)

---

## 🎓 Referencias

- [Spring Cloud Netflix Documentation](https://spring.io/projects/spring-cloud-netflix)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Google Cloud Best Practices](https://cloud.google.com/architecture/best-practices-vpc-design)

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub!**

---

## 📌 Notas Importantes

> **⚠️ IMPORTANTE:** Este proyecto consume créditos de GCP. Asegúrate de:
> - Monitorear el uso de recursos en GCP Console
> - Configurar alertas de presupuesto
> - Destruir ambientes no utilizados con `terraform destroy`
> - Revisar facturación regularmente

> **💡 TIP:** Para ambientes de desarrollo temporal, usa GKE Standard en lugar de Autopilot y configura auto-scaling a 0 nodos cuando no esté en uso
4. Click en `Apply & Restart`
5. Espera a que se inicie (toma unos minutos)

**macOS:**
1. Abre Docker Desktop desde Applications
2. Haz click en el ícono de Docker en la barra superior
3. Ve a `Preferences` → `Kubernetes`
4. Marca `Enable Kubernetes`
5. Click en `Apply & Restart`

**Linux:**
```bash
# Si usas Docker Desktop en Linux, sigue los mismos pasos del ícono de Docker
# O instala Docker Desktop desde: https://docs.docker.com/desktop/install/linux-installation/
```

### 3. Verificar que Kubernetes está habilitado

```bash
kubectl version
kubectl get nodes
```

Debe mostrar un nodo con nombre `docker-desktop` y status `Ready`.

### 4. Crear namespaces

```bash
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod
```

Verificar:
```bash
kubectl get namespaces
```

### 5. Levantar Jenkins

```bash
cd jenkins
docker-compose build --no-cache
docker-compose up -d
```

Acceder a Jenkins:
```
http://localhost:8080
```

Ver detalles completos en: [`setup/Jenkins_setup.md`](setup/Jenkins_setup.md)

### 6. Configurar Credenciales de Docker Hub

```bash
# Para namespace dev
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=dev

# Para namespace stage
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=stage

# Para namespace prod
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=prod
```

Ver detalles completos en: [`setup/config_setup.md`](setup/config_setup.md)

## Microservicios Configurados

Los siguientes 6 microservicios tienen pipelines CI/CD completamente configurados:

| Servicio | Puerto | Función |
|----------|--------|---------|
| **User Service** | 8700 | Gestión de usuarios y autenticación |
| **Product Service** | 8500 | Catálogo de productos |
| **Order Service** | 8300 | Gestión de órdenes y carritos |
| **Payment Service** | 8400 | Procesamiento de pagos |
| **Favourite Service** | 8800 | Gestión de favoritos |
| **Shipping Service** | 8600 | Envíos y logística |

### Componentes de Infraestructura

Además de los microservicios, se incluyen:

- **Config Server** - Centraliza la configuración de todos los servicios
- **Eureka (Service Discovery)** - Service registry para comunicación inter-servicios
- **Zipkin** - Distributed tracing para observabilidad
- **Proxy Client (API Gateway)** - Enrutamiento de requests

## Pipelines CI/CD

### Estructura de los Pipelines

Cada microservicio tiene 3 pipelines correspondientes a los 3 ambientes:

#### Pipeline DEV (Desarrollo)
- Clonar repositorio
- Build con Maven
- Construir imagen Docker
- Push a Docker Hub
- Desplegar en namespace `dev`
- **Tiempo**: ~5 min

#### Pipeline STAGE (Staging)
- Todos los pasos del dev
- Pruebas unitarias
- Pruebas de integración
- Pruebas de rendimiento
- Desplegar en namespace `stage`
- **Tiempo**: ~11 min

#### Pipeline PROD (Producción)
- Validación de cambios
- Construcción y pruebas completas
- Push a Docker Hub
- Despliegue en namespace `prod`
- Generación automática de Release Notes
- **Tiempo**: ~10 min

## Componentes de Infraestructura

### Docker Desktop Kubernetes

- **3 Namespaces**: dev, stage, prod
- **Contexto**: docker-desktop (por defecto)
- **Ventajas sobre Minikube**:
  - ✅ Más ligero y rápido
  - ✅ Integrado directamente en Docker Desktop
  - ✅ Mejor rendimiento
  - ✅ Actualización automática
  - ✅ Sin necesidad de comando `minikube start`

### Jenkins

- **Base**: jenkins/jenkins:2.479.1-lts-jdk17
- **Plugins**: Git, Docker, Kubernetes, Maven, Pipeline
- **Credenciales**: Docker Hub, Kubernetes kubeconfig
- **Puertos**: 8080 (UI), 50000 (agentes)

### Docker

- **Registro**: Docker Hub (docker.io)
- **Imágenes**: Base en Spring Boot
- **Volúmenes**: Datos persistentes para Jenkins

## Comandos Útiles

### Verificar estado de Kubernetes

```bash
# Ver nodos
kubectl get nodes

# Ver namespaces
kubectl get namespaces

# Ver contexto actual
kubectl config current-context

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=dev
```

### Gestionar pods y servicios

```bash
# Ver todos los pods en un namespace
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod

# Ver servicios
kubectl get services -n dev

# Ver logs de un pod
kubectl logs <pod-name> -n dev

# Acceder a un pod
kubectl exec -it <pod-name> -n dev -- /bin/bash

# Borrar un namespace (cuidado: elimina todo dentro)
kubectl delete namespace dev
```

### Port forwarding para acceder a servicios localmente

```bash
# Acceder a un servicio específico
kubectl port-forward -n dev svc/user-service 8700:8700
kubectl port-forward -n dev svc/product-service 8500:8500
kubectl port-forward -n dev svc/proxy-client 8200:8200

# Acceder a Zipkin (tracing)
kubectl port-forward -n dev svc/zipkin 9411:9411
```

### Gestionar Jenkins

```bash
# Ver logs de Jenkins
docker logs jenkins

# Reiniciar Jenkins
docker-compose -f jenkins/docker-compose.yml restart

# Parar Jenkins
docker-compose -f jenkins/docker-compose.yml stop

# Iniciar Jenkins
docker-compose -f jenkins/docker-compose.yml up -d
```

## Troubleshooting

### Kubernetes no está habilitado

**Error**: `unable to connect to the server: dial tcp 127.0.0.1:6443: connect: connection refused`

**Solución**:
1. Abre Docker Desktop
2. Ve a `Settings` → `Kubernetes`
3. Asegúrate de que `Enable Kubernetes` esté marcado
4. Click en `Apply & Restart`

### Pods no logran descargar imágenes

**Error**: `ImagePullBackOff` o `ErrImagePull`

**Solución**:
```bash
# Verifica que el secret de Docker Hub existe
kubectl get secrets -n dev

# Si no existe, créalo
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=dev
```

### Jenkins no se conecta a Kubernetes

**Error**: `Unable to connect to Kubernetes server`

**Solución**:
1. Verifica que `kubectl` esté funcionando: `kubectl version`
2. Configura la credencial de Kubernetes en Jenkins con el archivo kubeconfig
3. Ubicación típica: `~/.kube/config` en Windows/Mac/Linux

## Reportes y Métricas

Cada pipeline genera:

- **Configuración**: Texto y pantallazos de la configuración
- **Resultados**: Ejecución exitosa con detalles
- **Análisis**: Interpretación de pruebas de rendimiento
- **Release Notes**: Documentación de versiones desplegadas

## Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| Microservicios Configurados | 6 |
| Namespaces | 3 (dev, stage, prod) |
| Pipelines | 3 (dev, stage, master) |
| Pruebas Unitarias | ✅ Implementadas |
| Pruebas de Integración | ✅ Implementadas |
| Pruebas de Rendimiento | ✅ Implementadas |
| Tasa de Éxito | 83.33% |
