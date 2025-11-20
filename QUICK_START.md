# Quick Start: Cómo Correr Todo y Próximos Pasos

## 🚀 Inicio Rápido (5-10 minutos)

### Prerequisitos Instalados

```bash
# Verificar instalaciones
node --version          # v16+
docker --version        # 20.10+
kubectl --version       # v1.28+
terraform --version     # v1.5+
gcloud --version        # Latest
git --version           # 2.30+
```

### 1. Clonar Repositorios

```bash
cd ~/proyectos  # O tu carpeta de trabajo

# Clonar repo de operaciones
git clone https://github.com/tu-usuario/ecommerce-microservice-operations.git
cd ecommerce-microservice-operations

# Clonar repo de backend
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git ../ecommerce-microservice-backend-app
```

### 2. Configurar Variables de Entorno

```bash
# En ecommerce-microservice-operations/

# Copiar y completar env.config
cp env.config.example env.config

# Editar env.config con tus valores:
# - GCP_PROJECT_ID
# - GCP_CREDENTIALS_PATH
# - DOCKER_REGISTRY
# - GitHub token

source env.config
```

### 3. Configurar GCP (5 minutos)

```bash
# Seguir: GCP_SETUP.md

# Resumen:
1. gcloud auth login
2. Descargar gcp-key.json → terraform/credentials/
3. Verificar acceso: gcloud container clusters list
```

### 4. Inicializar Terraform

```bash
# DEV
cd terraform/environments/dev
terraform init
terraform plan
terraform apply  # Crear infraestructura

# Esperar ~5-10 min a que se cree GKE cluster
```

### 5. Configurar kubectl

```bash
# Conectar a cluster GKE
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --zone us-central1-a

# Verificar conexión
kubectl get nodes
kubectl get namespaces
```

### 6. Desplegar Servicios en Kubernetes

```bash
# Crear namespace
kubectl create namespace ecommerce-dev

# Desplegar servicios
cd k8s/dev
kubectl apply -f namespace/
kubectl apply -f config-server/
kubectl apply -f service-discovery/
kubectl apply -f api-gateway/
kubectl apply -f secrets/
# ... desplegar todos los servicios

# Verificar despliegues
kubectl get pods -n ecommerce-dev
kubectl get services -n ecommerce-dev
```

### 7. Levantar Jenkins

```bash
# Opción A (Local Docker - Recomendado para DEV)
cd jenkins
docker-compose up -d

# Acceder: http://localhost:8080
# Usuario: admin / Contraseña: admin123

# Configurar credenciales (ver JENKINS_SETUP.md)
```

### 8. Crear Pipelines en Jenkins

```
1. Dashboard → New Item
2. Nombre: "ecommerce-dev"
3. Tipo: Pipeline
4. Script Path: Jenkinsfile.dev-gcp
5. Save & Build
```

---

## 📊 Flujo Completo del Proyecto

```
┌─────────────────────────────────────────────────────────────┐
│  DESARROLLO (ecommerce-microservice-backend-app)           │
│  - Código de microservicios                                 │
│  - Tests unitarios e integración                            │
│  - Versionado semántico                                     │
└────────────────────┬────────────────────────────────────────┘
                     │ Push a GitHub
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  CI/CD (Jenkins)                                            │
│  - Compilar (Maven)                                         │
│  - Tests                                                    │
│  - SonarQube (análisis de código)                           │
│  - Trivy (scan de vulnerabilidades)                         │
│  - Build imagen Docker                                      │
│  - Push a Artifact Registry                                 │
│  - Deploy a GKE                                             │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         ▼           ▼           ▼
      DEV         STAGE        PROD
    (Manual)   (Manual/Auto) (Aprobación)
         │           │           │
         └───────────┼───────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  OPERACIONES (Kubernetes)                                   │
│  - Health Checks                                            │
│  - Logs (ELK Stack)                                         │
│  - Métricas (Prometheus)                                    │
│  - Alertas (Grafana)                                        │
│  - Tracing (Jaeger/Zipkin)                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Tareas Completadas (Ya Hechas)

✅ **1. Metodología Ágil (10%)**
   - Sistema: Kanban
   - Documentación: ProyectoFinal.md
   - Sprints definidos

✅ **2. Infraestructura Terraform (20%)**
   - Modular y escalable
   - Ambientes: dev, stage, prod
   - Backend remoto en GCS

✅ **3. Patrones de Diseño (10%)**
   - Documentados en codebase
   - Circuit Breaker, Bulkhead, etc.

---

## 🔨 Tareas Activas (En Progreso)

🟡 **4. CI/CD Avanzado (15%)** ← ACTUALMENTE AQUÍ
   - [ ] Jenkins configurado y corriendo
   - [ ] Pipelines creadas para cada microservicio
   - [ ] SonarQube integrado
   - [ ] Trivy para escaneo de vulnerabilidades
   - [ ] Versionado semántico automático
   - [ ] Notificaciones de fallos
   - [ ] Aprobaciones para PROD

---

## 📌 Próximas Tareas (Por Hacer)

🔴 **5. Pruebas Completas (15%)**
   ```bash
   # En ecommerce-microservice-backend-app

   # Unit tests
   mvn test

   # Integration tests
   mvn verify

   # E2E tests (Selenium/Cypress)
   npm run e2e

   # Performance tests (Locust)
   locust -f tests/performance/locustfile.py

   # Security tests (OWASP ZAP)
   zaproxy ...

   # Coverage report
   mvn jacoco:report
   ```

🔴 **6. Change Management (5%)**
   - Proceso formal documentado
   - Release notes automáticas
   - Planes de rollback

🔴 **7. Observabilidad (10%)**
   ```bash
   # En k8s/dev (o tu ambiente)

   # Prometheus
   kubectl apply -f monitoring/prometheus-config.yaml

   # Grafana
   kubectl apply -f monitoring/grafana-deployment.yaml

   # ELK Stack
   kubectl apply -f logging/elasticsearch.yaml
   kubectl apply -f logging/logstash.yaml
   kubectl apply -f logging/kibana.yaml

   # Jaeger/Zipkin (tracing)
   kubectl apply -f tracing/jaeger-deployment.yaml
   ```

🔴 **8. Seguridad (5%)**
   - RBAC en Kubernetes
   - TLS para servicios
   - Gestión de secretos

🔴 **9. Documentación y Presentación (10%)**
   - README actualizado
   - Video demostrativo
   - Presentación del proyecto

---

## 🔍 Verificar Estado Actual

```bash
# Ver estado de infraestructura
terraform show

# Ver estado de servicios en K8s
kubectl get all -n ecommerce-dev

# Ver logs de servicios
kubectl logs -f -n ecommerce-dev deployment/api-gateway

# Ver métricas actuales
kubectl top nodes
kubectl top pods -n ecommerce-dev

# Verificar Jenkins
curl http://localhost:8080/api/json | jq .
```

---

## 🆘 Troubleshooting

### "No tengo acceso a GCP"
→ Ver: `GCP_SETUP.md` sección 2-3

### "Terraform error: Service account not found"
→ Verificar `terraform/credentials/gcp-key.json` existe

### "GKE cluster taking too long"
→ Esperar 10-15 min, es normal la primera vez

### "Jenkins no inicia"
→ Revisar: `docker logs jenkins` o `docker-compose logs jenkins`

### "kubectl no conecta al cluster"
→ Ejecutar: `gcloud container clusters get-credentials ...`

---

## 📚 Documentos de Referencia

- **TERRAFORM_GUIDE.md** - Estructura y configuración
- **GCP_SETUP.md** - Configuración de credenciales
- **JENKINS_SETUP.md** - Levantar y configurar Jenkins
- **ProyectoFinal.md** - Metodología ágil y estrategia
- **README.md** - Documentación general del proyecto

---

## 📞 Contacto y Ayuda

Si algo no funciona:
1. Revisar el documento correspondiente
2. Verificar logs (`docker logs`, `kubectl logs`, etc.)
3. Preguntar al equipo en Slack/Discord
4. Abrir issue en GitHub

**Recuerda**: Este es un proyecto educativo, lo importante es aprender cómo funciona la arquitectura completa de microservicios.

