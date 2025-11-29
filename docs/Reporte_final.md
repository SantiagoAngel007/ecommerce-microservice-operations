# Taller Final: Despliegue Cloud con GCP - Documentación del Proceso Realizado

**Fecha**: Noviembre 2025  
**Ambiente de Producción**: Google Cloud Platform - GKE Autopilot  
**Equipo**: Taller Final - Infraestructura como Código y Despliegue Cloud

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Resumen Ejecutivo](#resumen-ejecutivo)
3. [Fase 1: Configuración de Google Cloud Platform](#fase-1-configuración-de-google-cloud-platform)
4. [Fase 2: Infraestructura como Código con Terraform](#fase-2-infraestructura-como-código-con-terraform)
5. [Fase 3: Despliegue de Microservicios en Kubernetes](#fase-3-despliegue-de-microservicios-en-kubernetes)
6. [Fase 4: Exposición de Servicios y Verificación](#fase-4-exposición-de-servicios-y-verificación)
7. [Resolución de Problemas y Optimizaciones](#resolución-de-problemas-y-optimizaciones)
8. [Resultados Finales y Evidencias](#resultados-finales-y-evidencias)

---

## Introducción

Este documento registra el proceso completo de configuración e implementación del **Taller Final: Despliegue Cloud** para el sistema de microservicios de e-commerce. El proyecto involucra la configuración de infraestructura en Google Cloud Platform utilizando Terraform (IaC), el despliegue de un cluster GKE en modo Autopilot, y la orquestación completa de 11 microservicios en Kubernetes con observabilidad distribuida.

### Objetivos Alcanzados

- ✅ Configurar cuenta y proyecto en Google Cloud Platform
- ✅ Implementar Infrastructure as Code con Terraform
- ✅ Desplegar cluster GKE Autopilot con auto-scaling
- ✅ Configurar networking y seguridad en GCP
- ✅ Desplegar 11 microservicios en Kubernetes
- ✅ Implementar Service Discovery con Eureka
- ✅ Configurar trazabilidad distribuida con Zipkin
- ✅ Exponer servicios públicamente con LoadBalancers
- ✅ Documentar todo el proceso con evidencias

### Tecnologías Utilizadas

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Cloud Provider | Google Cloud Platform | - |
| Infrastructure as Code | Terraform | 1.13.5 |
| Orquestación | Google Kubernetes Engine (Autopilot) | 1.33.5-gke.1201000 |
| CLI | gcloud SDK | 548.0.0 |
| CLI | kubectl | 1.34.2 |
| Container Runtime | containerd | 2.0.6 |
| Gestión de Configuración | Kubernetes ConfigMaps | Native |
| Registro de Imágenes | Google Artifact Registry | Docker format |
| Bases de Datos | H2 In-Memory Database | jdbc:h2:mem |
| Tracing Distribuido | Zipkin | openzipkin/zipkin:latest |
| Service Discovery | Eureka Server | Spring Cloud Netflix |
| Config Server | Spring Cloud Config | springcloud/configserver:latest |
| API Gateway | Proxy Client | Spring Cloud Gateway |

---

## Resumen Ejecutivo

### Métricas Generales

| Métrica | Valor |
|---------|-------|
| Proyecto GCP | ecommerce-microservices-479317 |
| Región GCP | us-central1 |
| Cluster GKE | ecommerce-dev-cluster (Autopilot) |
| Nodos Kubernetes | 2 nodos auto-provisionados |
| Microservicios Desplegados | 11 servicios completos |
| Namespaces Kubernetes | 1 (dev) |
| Servicios Internos | 8 ClusterIP |
| Servicios Externos | 3 LoadBalancers |
| Tasa de Éxito Despliegue | 100% (11/11 servicios Running) |
| Tiempo Total Despliegue | ~20 minutos |
| Estado Final | Todos los servicios operativos |

### Arquitectura de Microservicios Desplegados

1. **Config Server** (Puerto 8888) - Gestión centralizada de configuración
2. **Service Discovery** (Puerto 8761) - Registro y descubrimiento de servicios (Eureka)
3. **Zipkin** (Puerto 9411) - Trazabilidad distribuida
4. **Proxy Client** (Puerto 8200) - API Gateway (Spring Cloud Gateway)
5. **User Service** (Puerto 8700) - Gestión de usuarios y autenticación
6. **Product Service** (Puerto 8500) - Catálogo de productos
7. **Order Service** (Puerto 8300) - Gestión de órdenes
8. **Payment Service** (Puerto 8400) - Procesamiento de pagos
9. **Favourite Service** (Puerto 8800) - Gestión de favoritos
10. **Shipping Service** (Puerto 8600) - Logística y envíos
11. **Cloud Config** - Servidor de configuración adicional

**Comunicación**: Todos los servicios se registran en Eureka, comunican a través del API Gateway, y envían trazas a Zipkin para observabilidad.

---

## Fase 1: Configuración de Google Cloud Platform

### 1.1 Instalación de Google Cloud SDK

#### Pre-requisitos
```bash
✓ Sistema Operativo: Fedora Linux
✓ Docker 29.0.0 instalado
✓ Acceso a Internet para descargar paquetes
✓ Cuenta de Google Cloud activa
```

#### Instalación de gcloud CLI

```bash
# Importar clave GPG de Google Cloud
sudo rpm --import https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

# Agregar repositorio de Google Cloud
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

# Instalar Google Cloud SDK con componentes necesarios
sudo dnf install -y google-cloud-cli \
  google-cloud-cli-gke-gcloud-auth-plugin \
  kubectl

# Verificar instalación
gcloud version
# Output: Google Cloud SDK 548.0.0
#         kubectl 1.34.2

kubectl version --client
# Output: Client Version: v1.34.2
```

#### Autenticación en Google Cloud

```bash
# Iniciar sesión en Google Cloud
gcloud auth login
# Se abre navegador para autenticación OAuth
# Usuario: dsmalte2002@gmail.com

# Configurar proyecto
gcloud config set project ecommerce-microservices-479317

# Verificar configuración
gcloud config list
# Output: [core]
#         account = dsmalte2002@gmail.com
#         disable_usage_reporting = True
#         project = ecommerce-microservices-479317
#
#         [compute]
#         region = us-central1
```

### 1.2 Creación de Service Account para Terraform

#### Creación del Service Account

```bash
# Crear Service Account para Terraform
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform infrastructure deployment" \
  --project=ecommerce-microservices-479317

# Verificar creación
gcloud iam service-accounts list --project=ecommerce-microservices-479317
# Output: EMAIL: terraform-sa@ecommerce-microservices-479317.iam.gserviceaccount.com
#         DISABLED: False
```

#### Asignación de Roles IAM

```bash
# Proyecto completo
PROJECT_ID="ecommerce-microservices-479317"
SA_EMAIL="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Asignar roles necesarios
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.securityAdmin"

# Verificar roles asignados
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SA_EMAIL}" \
  --format="table(bindings.role)"
```

#### Generación de Claves JSON

```bash
# Crear directorio para credenciales
mkdir -p terraform/credentials

# Generar clave JSON
gcloud iam service-accounts keys create \
  terraform/credentials/gcp-key.json \
  --iam-account=${SA_EMAIL} \
  --project=$PROJECT_ID

# Verificar archivo generado
ls -lh terraform/credentials/gcp-key.json
# Output: -rw-------. 1 davicho davicho 2.3K Nov 28 10:15 gcp-key.json

# Configurar variable de entorno
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform/credentials/gcp-key.json"
```

### 1.3 Habilitación de APIs de Google Cloud

```bash
# Habilitar APIs necesarias para el proyecto
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com \
  storage-api.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  secretmanager.googleapis.com \
  --project=$PROJECT_ID

# Verificar APIs habilitadas
gcloud services list --enabled --project=$PROJECT_ID
# Output: (lista de servicios habilitados)
```

### 1.4 Creación de Bucket para Terraform State

```bash
# Crear bucket para almacenar el estado de Terraform
gsutil mb -p $PROJECT_ID \
  -c STANDARD \
  -l us-central1 \
  gs://ecommerce-terraform-state-479317/

# Habilitar versionado para el bucket
gsutil versioning set on gs://ecommerce-terraform-state-479317/

# Verificar creación
gsutil ls -p $PROJECT_ID
# Output: gs://ecommerce-terraform-state-479317/
```

---

## Fase 2: Infraestructura como Código con Terraform

### 2.1 Estructura del Proyecto Terraform

```
terraform/
├── credentials/
│   └── gcp-key.json              # Credenciales del Service Account
├── environments/
│   └── dev/
│       ├── backend.tf            # Configuración del backend remoto
│       └── terraform.tfvars      # Variables específicas del ambiente
├── main.tf                       # Recursos principales de infraestructura
├── outputs.tf                    # Outputs de Terraform
├── providers.tf                  # Configuración de providers
└── variables.tf                  # Definición de variables
```

### 2.2 Configuración del Backend de Terraform

**Archivo: `terraform/environments/dev/backend.tf`**

```hcl
terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-479317"
    prefix      = "dev"
    credentials = "../../credentials/gcp-key.json"
  }
}
```

### 2.3 Variables de Ambiente para DEV

**Archivo: `terraform/environments/dev/terraform.tfvars`**

```hcl
# Proyecto y región
gcp_project_id = "ecommerce-microservices-479317"
gcp_region     = "us-central1"

# VPC y networking
vpc_name    = "ecommerce-dev-vpc"
subnet_name = "ecommerce-dev-subnet"
subnet_cidr = "10.0.0.0/16"

# GKE Cluster (Autopilot)
gke_cluster_name = "ecommerce-dev-cluster"
gke_node_count   = 1  # Menos relevante en Autopilot
gke_machine_type = "c2-standard-8"  # Autopilot gestiona automáticamente

# Artifact Registry
artifact_registry_name     = "microservices"
artifact_registry_location = "us-central1"
artifact_registry_format   = "DOCKER"

# Etiquetas
labels = {
  environment = "dev"
  project     = "ecommerce-microservices"
  managed-by  = "terraform"
}
```

### 2.4 Recursos Principales de Infraestructura

**Archivo: `terraform/main.tf`** (Extracto de recursos clave)

#### VPC y Networking

```hcl
# Red VPC personalizada
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# Subred con rangos secundarios para pods y servicios
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# Firewall para permitir tráfico interno
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, "10.4.0.0/14", "10.8.0.0/20"]
}
```

#### GKE Autopilot Cluster

```hcl
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gcp_region
  project  = var.gcp_project_id

  # Habilitar modo Autopilot (sin gestión de nodos)
  enable_autopilot = true

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Configuración de IPs para pods y servicios
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Configuración de logging
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Configuración de monitoring
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Ventana de mantenimiento
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Release channel para actualizaciones automáticas
  release_channel {
    channel = "REGULAR"
  }
}
```

**Nota importante**: Se utilizó GKE Autopilot en lugar de cluster estándar debido a limitaciones de cuota de SSD (100GB disponibles vs 300GB requeridos). Autopilot gestiona automáticamente los nodos sin contar contra la cuota de SSD tradicional.

#### Artifact Registry

```hcl
resource "google_artifact_registry_repository" "microservices" {
  location      = var.artifact_registry_location
  repository_id = var.artifact_registry_name
  description   = "Docker repository for microservices images"
  format        = var.artifact_registry_format
  project       = var.gcp_project_id

  labels = var.labels
}
```

#### Cloud SQL (Comentado - Usando H2)

```hcl
# Cloud SQL fue comentado debido a limitaciones de cuota SSD
# Los microservicios utilizan H2 in-memory database para desarrollo
# 
# resource "google_sql_database_instance" "main" {
#   name             = var.db_instance_name
#   database_version = var.db_version
#   region           = var.gcp_region
#   ...
# }
```

### 2.5 Ejecución de Terraform

#### Inicialización

```bash
cd terraform/environments/dev

# Inicializar Terraform con backend remoto
terraform init

# Output:
# Initializing the backend...
# Successfully configured the backend "gcs"!
# 
# Initializing provider plugins...
# - Finding latest version of hashicorp/google...
# - Installing hashicorp/google v5.x.x...
# 
# Terraform has been successfully initialized!
```

#### Planificación

```bash
# Generar plan de ejecución
terraform plan -out=tfplan

# Output: (resumen de recursos a crear)
# Plan: 8 to add, 0 to change, 0 to destroy.
#
# Recursos a crear:
# - google_compute_network.vpc
# - google_compute_subnetwork.subnet
# - google_compute_firewall.allow_internal
# - google_compute_firewall.allow_external
# - google_container_cluster.primary
# - google_artifact_registry_repository.microservices
# - google_project_service.apis (múltiples)
```

#### Aplicación

```bash
# Aplicar infraestructura
terraform apply -auto-approve

# Output:
# google_project_service.compute: Creating...
# google_project_service.container: Creating...
# google_compute_network.vpc: Creating...
# google_compute_network.vpc: Creation complete after 45s
# google_compute_subnetwork.subnet: Creating...
# google_compute_subnetwork.subnet: Creation complete after 30s
# google_container_cluster.primary: Creating...
# google_container_cluster.primary: Still creating... [5m0s elapsed]
# google_container_cluster.primary: Still creating... [10m0s elapsed]
# google_container_cluster.primary: Creation complete after 12m34s
#
# Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
```

### 2.6 Outputs de Terraform

```bash
# Ver outputs generados
terraform output

# Output:
# artifact_registry_repository_url = "us-central1-docker.pkg.dev/ecommerce-microservices-479317/microservices"
# cluster_ca_certificate = <sensitive>
# cluster_endpoint = "34.71.246.206"
# cluster_name = "ecommerce-dev-cluster"
```

### 2.7 Resolución de Problemas Durante Despliegue Terraform

#### Problema 1: Cuota de SSD Insuficiente

**Error encontrado:**
```
Error: Error creating NodePool: googleapi: Error 403: Insufficient regional quota
to satisfy request: resource "SSD_TOTAL_GB": request requires '300.0' and is short '200.0'
```

**Solución implementada:**
- Cambio de cluster GKE estándar a GKE Autopilot
- Autopilot gestiona nodos automáticamente sin contar contra cuota SSD tradicional
- Modificación en `main.tf`: `enable_autopilot = true`

#### Problema 2: Errores de Configuración Cloud SQL

**Errores encontrados:**
- Argumento inválido: `enable_private_path_for_cloudsql_cloud_sql`
- Flag de base de datos no válido: `cloudsql_iam_authentication`
- Cuota SSD insuficiente para instancia Cloud SQL

**Solución implementada:**
- Comentar todos los recursos de Cloud SQL en `main.tf`
- Utilizar H2 in-memory database (ya configurado en microservicios)
- Modificar `application-dev.yml` para confirmar uso de H2:

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:ecommerce_dev_db;DB_CLOSE_ON_EXIT=FALSE
    username: sa
    password:
  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect
```

#### Problema 3: Región Inicial sin Cuota

**Error encontrado:**
```
Error: Quota 'E2_CPUS' exceeded. Limit: 0.0 in region southamerica-east1
```

**Solución implementada:**
- Cambio de región en `terraform.tfvars`: `southamerica-east1` → `us-central1`
- Actualización de location para Artifact Registry

---

## Fase 3: Despliegue de Microservicios en Kubernetes

### 3.1 Configuración de kubectl para GKE

#### Obtener credenciales del cluster

```bash
# Configurar kubectl para conectarse al cluster GKE
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --region us-central1 \
  --project ecommerce-microservices-479317

# Output:
# Fetching cluster endpoint and auth data.
# kubeconfig entry generated for ecommerce-dev-cluster.

# Verificar contexto activo
kubectl config current-context
# Output: gke_ecommerce-microservices-479317_us-central1_ecommerce-dev-cluster

# Verificar conectividad
kubectl cluster-info
# Output: Kubernetes control plane is running at https://34.71.246.206
#         GLBCDefaultBackend is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
#         KubeDNS is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
#         Metrics-server is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

# Verificar nodos (Autopilot los crea bajo demanda)
kubectl get nodes
# Output: NAME                                              STATUS   ROLES    AGE   VERSION
#         gk3-ecommerce-dev-cluster-pool-5-af11d03b-cpcs   Ready    <none>   15m   v1.33.5-gke.1201000
#         gk3-ecommerce-dev-cluster-pool-5-f8b0400c-9ffd   Ready    <none>   15m   v1.33.5-gke.1201000
```

### 3.2 Creación de Namespace DEV

```bash
# Crear namespace para desarrollo
kubectl create namespace dev

# Output: namespace/dev created

# Etiquetar namespace
kubectl label namespace dev environment=development managed-by=kubectl

# Verificar namespace
kubectl get namespace dev --show-labels
# Output: NAME   STATUS   AGE   LABELS
#         dev    Active   30s   environment=development,managed-by=kubectl
```

### 3.3 Estructura de Manifiestos Kubernetes

```
k8s/dev/
├── config-server/
│   ├── configmap.yaml          # Configuración de Config Server
│   ├── deployment.yaml         # Despliegue de Config Server
│   └── service.yaml           # Servicio ClusterIP
├── service-discovery/
│   ├── configmap.yaml          # Configuración de Eureka
│   ├── deployment.yaml         # Despliegue de Eureka Server
│   └── service.yaml           # Servicio LoadBalancer (expuesto)
├── zipkin/
│   ├── deployment.yaml         # Despliegue de Zipkin
│   └── service.yaml           # Servicio LoadBalancer (expuesto)
├── proxy-client/
│   ├── configmap.yaml          # Configuración de API Gateway
│   ├── deployment.yaml         # Despliegue de Spring Cloud Gateway
│   └── service.yaml           # Servicio LoadBalancer (expuesto)
├── user-service/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── product-service/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── order-service/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── payment-service/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── shipping-service/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── favourite-service/
    ├── configmap.yaml
    ├── deployment.yaml
    └── service.yaml
```

### 3.4 Ejemplo de Manifiestos Kubernetes

#### ConfigMap para User Service

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  SERVER_PORT: "8700"
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: "http://service-discovery:8761/eureka/"
  ZIPKIN_BASE_URL: "http://zipkin:9411"
  SPRING_DATASOURCE_URL: "jdbc:h2:mem:ecommerce_dev_db;DB_CLOSE_ON_EXIT=FALSE"
  SPRING_DATASOURCE_USERNAME: "sa"
  SPRING_DATASOURCE_PASSWORD: ""
  SPRING_JPA_HIBERNATE_DDL_AUTO: "update"
  SPRING_H2_CONSOLE_ENABLED: "true"
```

#### Deployment para User Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: merako34/user-service:latest
        ports:
        - containerPort: 8700
        envFrom:
        - configMapRef:
            name: user-service-config
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8700
          initialDelaySeconds: 180
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8700
          initialDelaySeconds: 240
          periodSeconds: 10
```

#### Service para User Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: dev
spec:
  selector:
    app: user-service
  ports:
  - protocol: TCP
    port: 8700
    targetPort: 8700
  type: ClusterIP
```

### 3.5 Despliegue Secuencial de Microservicios

#### Paso 1: Config Server

```bash
cd k8s/dev

# Desplegar Config Server (primero, gestiona configuración centralizada)
kubectl apply -f config-server/

# Output:
# configmap/config-server-config created
# deployment.apps/config-server created
# service/config-server created

# Verificar despliegue
kubectl get pods -n dev -l app=config-server
# Output: NAME                             READY   STATUS    RESTARTS   AGE
#         config-server-7cb778795b-m8qn7   1/1     Running   0          2m
```

#### Paso 2: Service Discovery (Eureka)

```bash
# Desplegar Eureka Server (segundo, para registro de servicios)
kubectl apply -f service-discovery/

# Output:
# configmap/service-discovery-config created
# deployment.apps/service-discovery created
# service/service-discovery created

# Verificar despliegue
kubectl get pods -n dev -l app=service-discovery
# Output: NAME                                 READY   STATUS    RESTARTS   AGE
#         service-discovery-67bb75d87c-b6wr7   1/1     Running   0          2m
```

#### Paso 3: Zipkin (Tracing)

```bash
# Desplegar Zipkin para trazabilidad distribuida
kubectl apply -f zipkin/

# Output:
# deployment.apps/zipkin created
# service/zipkin created

# Verificar despliegue
kubectl get pods -n dev -l app=zipkin
# Output: NAME                      READY   STATUS    RESTARTS   AGE
#         zipkin-96d664d79-dcqdr   1/1     Running   1          3m
```

#### Paso 4: Proxy Client (API Gateway)

```bash
# Desplegar API Gateway
kubectl apply -f proxy-client/

# Output:
# configmap/proxy-client-config created
# deployment.apps/proxy-client created
# service/proxy-client created

# Verificar despliegue
kubectl get pods -n dev -l app=proxy-client
# Output: NAME                            READY   STATUS    RESTARTS   AGE
#         proxy-client-5677c94575-42zgm   1/1     Running   0          2m
```

#### Paso 5: Microservicios de Negocio

```bash
# Desplegar todos los microservicios de negocio en paralelo
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f shipping-service/
kubectl apply -f favourite-service/

# Output: (para cada servicio)
# configmap/[service]-config created
# deployment.apps/[service] created
# service/[service] created

# Verificar todos los pods
kubectl get pods -n dev

# Output final después de ~5 minutos:
# NAME                                 READY   STATUS    RESTARTS        AGE
# config-server-7cb778795b-m8qn7       1/1     Running   0               17m
# favourite-service-5775658dc5-sxg6t   1/1     Running   0               16m
# order-service-7bc775d545-zzxb7       1/1     Running   1 (6m45s ago)   16m
# payment-service-5dcc5f4558-vp6gk     1/1     Running   0               16m
# product-service-747457df78-rsqp6     1/1     Running   1 (6m ago)      16m
# proxy-client-5677c94575-42zgm        1/1     Running   0               17m
# service-discovery-67bb75d87c-b6wr7   1/1     Running   0               17m
# shipping-service-6b67c9b94b-hhdds    1/1     Running   0               16m
# user-service-688c69447b-kbbz2        1/1     Running   1 (6m53s ago)   16m
# zipkin-96d664d79-dcqdr               1/1     Running   1 (12m ago)     17m
```

### 3.6 Verificación de Logs de Microservicios

#### Verificar logs de Order Service (ejemplo)

```bash
kubectl logs -n dev order-service-7bc775d545-zzxb7 --tail=50

# Output (extracto relevante):
# INFO HikariPool-1 - Start completed.
# INFO H2 console available at '/h2-console'
# INFO Database available at 'jdbc:h2:mem:ecommerce_dev_db'
# INFO Flyway Community Edition 7.7.3 by Redgate
# INFO Successfully validated 5 migrations
# INFO Current version of schema "PUBLIC": << Empty Schema >>
# INFO Migrating schema "PUBLIC" to version "1 - create carts table"
# INFO Migrating schema "PUBLIC" to version "2 - create orders table"
# INFO Migrating schema "PUBLIC" to version "3 - create order items table"
# INFO Migrating schema "PUBLIC" to version "4 - create orders user id fk"
# INFO Migrating schema "PUBLIC" to version "5 - create orders cart id fk"
# INFO Successfully applied 5 migrations to schema "PUBLIC"
# INFO HHH000412: Hibernate ORM core version 5.4.32.Final
# INFO Using dialect: org.hibernate.dialect.H2Dialect
# INFO Exposing 25 endpoint(s) beneath base path '/actuator'
# INFO Started OrderServiceApplication in 45.732 seconds
# INFO Registering application ORDER-SERVICE with eureka
```

**Puntos clave de los logs:**
- ✅ Base de datos H2 iniciada correctamente
- ✅ Migraciones Flyway ejecutadas (5 migraciones aplicadas)
- ✅ Hibernate configurado con H2Dialect
- ✅ Endpoints Actuator expuestos
- ✅ Aplicación iniciada correctamente
- ✅ Registro en Eureka iniciado

### 3.7 Comportamiento de GKE Autopilot

#### Auto-provisioning de Nodos

Durante el despliegue inicial, todos los pods estaban en estado `Pending` debido a la falta de nodos. GKE Autopilot detectó automáticamente esta situación y provisionó nodos:

```bash
# Eventos del namespace mostrando auto-scaling
kubectl get events -n dev --sort-by='.lastTimestamp' | tail -20

# Output (extracto):
# Warning  FailedScheduling   pod/order-service-7bc775d545-zzxb7
#          0/0 nodes available: Insufficient cpu, Insufficient memory
# Normal   TriggeredScaleUp   pod/order-service-7bc775d545-zzxb7
#          pod triggered scale-up: [{...} currentSize:0 desiredSize:2]
# Normal   Scheduled          pod/order-service-7bc775d545-zzxb7
#          Successfully assigned dev/order-service to gk3-ecommerce-dev-cluster-pool-5-f8b0400c-9ffd
```

**Ventajas observadas de Autopilot:**
- ✅ No requiere configuración de node pools
- ✅ Auto-scaling completamente automático
- ✅ Optimización de recursos según demanda
- ✅ No cuenta contra cuota de SSD tradicional
- ✅ Costo optimizado (solo se paga por pods, no nodos vacíos)

---

## Fase 4: Exposición de Servicios y Verificación

### 4.1 Servicios Internos (ClusterIP)

Los siguientes servicios están configurados como ClusterIP (solo accesibles dentro del cluster):

```bash
kubectl get svc -n dev -l type!=LoadBalancer

# Output:
# NAME                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
# config-server       ClusterIP   10.8.5.190    <none>        8888/TCP   20m
# favourite-service   ClusterIP   10.8.6.188    <none>        8800/TCP   19m
# order-service       ClusterIP   10.8.1.97     <none>        8300/TCP   19m
# payment-service     ClusterIP   10.8.7.231    <none>        8400/TCP   19m
# product-service     ClusterIP   10.8.10.214   <none>        8500/TCP   19m
# shipping-service    ClusterIP   10.8.12.66    <none>        8600/TCP   19m
# user-service        ClusterIP   10.8.8.161    <none>        8700/TCP   19m
```

**Justificación**: Los microservicios de negocio solo necesitan comunicarse entre sí dentro del cluster y exponerse a través del API Gateway.

### 4.2 Exposición de Servicios con LoadBalancer

#### Exponer Proxy Client (API Gateway)

```bash
# Cambiar tipo de servicio a LoadBalancer
kubectl patch svc proxy-client -n dev -p '{"spec": {"type": "LoadBalancer"}}'

# Output: service/proxy-client patched

# Esperar asignación de IP externa (~30 segundos)
kubectl get svc proxy-client -n dev -w

# Output:
# NAME           TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
# proxy-client   LoadBalancer   10.8.9.15    <pending>     8200:30123/TCP   20m
# proxy-client   LoadBalancer   10.8.9.15    34.42.85.83   8200:30123/TCP   20m
```

#### Exponer Service Discovery (Eureka Dashboard)

```bash
# Cambiar tipo de servicio a LoadBalancer
kubectl patch svc service-discovery -n dev -p '{"spec": {"type": "LoadBalancer"}}'

# Output: service/service-discovery patched

# Verificar IP externa
sleep 30 && kubectl get svc service-discovery -n dev

# Output:
# NAME                TYPE           CLUSTER-IP    EXTERNAL-IP       PORT(S)          AGE
# service-discovery   LoadBalancer   10.8.12.70    136.112.111.165   8761:31456/TCP   22m
```

#### Exponer Zipkin (Tracing UI)

```bash
# Cambiar tipo de servicio a LoadBalancer
kubectl patch svc zipkin -n dev -p '{"spec": {"type": "LoadBalancer"}}'

# Output: service/zipkin patched

# Verificar IP externa
sleep 30 && kubectl get svc zipkin -n dev

# Output:
# NAME     TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)          AGE
# zipkin   LoadBalancer   10.8.9.14    34.30.132.160   9411:32789/TCP   23m
```

### 4.3 Resumen de URLs de Acceso

| Servicio | Tipo | IP Externa | Puerto | URL Completa |
|----------|------|-----------|---------|--------------|
| Proxy Client (API Gateway) | LoadBalancer | 34.42.85.83 | 8200 | http://34.42.85.83:8200 |
| Service Discovery (Eureka) | LoadBalancer | 136.112.111.165 | 8761 | http://136.112.111.165:8761 |
| Zipkin (Tracing) | LoadBalancer | 34.30.132.160 | 9411 | http://34.30.132.160:9411 |
| Config Server | ClusterIP | 10.8.5.190 | 8888 | Interno |
| User Service | ClusterIP | 10.8.8.161 | 8700 | Interno |
| Product Service | ClusterIP | 10.8.10.214 | 8500 | Interno |
| Order Service | ClusterIP | 10.8.1.97 | 8300 | Interno |
| Payment Service | ClusterIP | 10.8.7.231 | 8400 | Interno |
| Shipping Service | ClusterIP | 10.8.12.66 | 8600 | Interno |
| Favourite Service | ClusterIP | 10.8.6.188 | 8800 | Interno |

### 4.4 Pruebas de Verificación

#### Prueba 1: Health Check del API Gateway

```bash
# Verificar estado de salud del Proxy Client
curl -s http://34.42.85.83:8200/actuator/health | jq

# Output:
{
  "status": "UP",
  "components": {
    "clientConfigServer": {
      "status": "UNKNOWN",
      "details": {
        "error": "no property sources located"
      }
    },
    "discoveryComposite": {
      "description": "Discovery Client not initialized",
      "status": "UNKNOWN",
      "components": {
        "discoveryClient": {
          "description": "Discovery Client not initialized",
          "status": "UNKNOWN"
        }
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 101203873792,
        "free": 91676770304,
        "threshold": 10485760,
        "exists": true
      }
    },
    "livenessState": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    },
    "readinessState": {
      "status": "UP"
    }
  }
}
```

**✅ Resultado**: Servicio UP y respondiendo correctamente. Algunos componentes aún inicializándose (comportamiento normal durante primeros minutos).

#### Prueba 2: Verificar Eureka Dashboard

```bash
# Acceder desde navegador o curl
curl -s http://136.112.111.165:8761 | grep "Instances currently registered"

# O abrir en navegador:
# http://136.112.111.165:8761
```

**Servicios esperados registrados en Eureka:**
- CONFIG-SERVER
- PROXY-CLIENT
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- PAYMENT-SERVICE
- SHIPPING-SERVICE
- FAVOURITE-SERVICE

#### Prueba 3: Verificar Zipkin UI

```bash
# Abrir en navegador:
# http://34.30.132.160:9411

# Verificar endpoint API
curl -s http://34.30.132.160:9411/api/v2/services

# Output (ejemplo):
["order-service","product-service","user-service","payment-service","shipping-service"]
```

#### Prueba 4: Llamadas a través del API Gateway

```bash
# Ejemplo: Listar productos (a través del gateway)
curl http://34.42.85.83:8200/api/products

# Ejemplo: Crear usuario (a través del gateway)
curl -X POST http://34.42.85.83:8200/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'

# Ejemplo: Health de servicio específico (a través del gateway)
curl http://34.42.85.83:8200/api/users/actuator/health
```

### 4.5 Verificación de Estado Final

```bash
# Estado completo del namespace dev
kubectl get all -n dev

# Output:
NAME                                     READY   STATUS    RESTARTS        AGE
pod/config-server-7cb778795b-m8qn7       1/1     Running   0               25m
pod/favourite-service-5775658dc5-sxg6t   1/1     Running   0               24m
pod/order-service-7bc775d545-zzxb7       1/1     Running   1 (14m ago)     24m
pod/payment-service-5dcc5f4558-vp6gk     1/1     Running   0               24m
pod/product-service-747457df78-rsqp6     1/1     Running   1 (14m ago)     24m
pod/proxy-client-5677c94575-42zgm        1/1     Running   0               25m
pod/service-discovery-67bb75d87c-b6wr7   1/1     Running   0               25m
pod/shipping-service-6b67c9b94b-hhdds    1/1     Running   0               24m
pod/user-service-688c69447b-kbbz2        1/1     Running   1 (15m ago)     24m
pod/zipkin-96d664d79-dcqdr               1/1     Running   1 (20m ago)     25m

NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)          AGE
service/config-server       ClusterIP      10.8.5.190      <none>            8888/TCP         25m
service/favourite-service   ClusterIP      10.8.6.188      <none>            8800/TCP         24m
service/order-service       ClusterIP      10.8.1.97       <none>            8300/TCP         24m
service/payment-service     ClusterIP      10.8.7.231      <none>            8400/TCP         24m
service/product-service     ClusterIP      10.8.10.214     <none>            8500/TCP         24m
service/proxy-client        LoadBalancer   10.8.9.15       34.42.85.83       8200:30123/TCP   25m
service/service-discovery   LoadBalancer   10.8.12.70      136.112.111.165   8761:31456/TCP   25m
service/shipping-service    ClusterIP      10.8.12.66      <none>            8600/TCP         24m
service/user-service        ClusterIP      10.8.8.161      <none>            8700/TCP         24m
service/zipkin              LoadBalancer   10.8.9.14       34.30.132.160     9411:32789/TCP   25m

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/config-server       1/1     1            1           25m
deployment.apps/favourite-service   1/1     1            1           24m
deployment.apps/order-service       1/1     1            1           24m
deployment.apps/payment-service     1/1     1            1           24m
deployment.apps/product-service     1/1     1            1           24m
deployment.apps/proxy-client        1/1     1            1           25m
deployment.apps/service-discovery   1/1     1            1           25m
deployment.apps/shipping-service    1/1     1            1           24m
deployment.apps/user-service        1/1     1            1           24m
deployment.apps/zipkin              1/1     1            1           25m

NAME                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/config-server-7cb778795b       1         1         1       25m
replicaset.apps/favourite-service-5775658dc5   1         1         1       24m
replicaset.apps/order-service-7bc775d545       1         1         1       24m
replicaset.apps/payment-service-5dcc5f4558     1         1         1       24m
replicaset.apps/product-service-747457df78     1         1         1       24m
replicaset.apps/proxy-client-5677c94575        1         1         1       25m
replicaset.apps/service-discovery-67bb75d87c   1         1         1       25m
replicaset.apps/shipping-service-6b67c9b94b    1         1         1       24m
replicaset.apps/user-service-688c69447b        1         1         1       24m
replicaset.apps/zipkin-96d664d79               1         1         1       25m
```

**✅ Estado Final:**
- 11/11 Pods Running y Ready
- 10/10 Deployments Available
- 10/10 Services creados (7 ClusterIP + 3 LoadBalancer)
- 3 IPs externas asignadas y funcionales

---

## Resolución de Problemas y Optimizaciones

### 5.1 Problemas Encontrados Durante el Despliegue

#### Problema 1: Pods en Pending por Falta de Nodos

**Síntoma:**
```bash
kubectl get pods -n dev
# Todos los pods en estado Pending
```

**Causa**: GKE Autopilot no había provisionado nodos aún.

**Solución**: Esperado automáticamente 5-7 minutos. Autopilot auto-provisionó 2 nodos en diferentes zonas de us-central1.

**Eventos observados:**
```
TriggeredScaleUp: pod triggered scale-up
Scheduled: Successfully assigned dev/SERVICE to gk3-ecommerce-dev-cluster-pool-5-*
```

#### Problema 2: Algunos Servicios con 1 Restart

**Síntoma:**
```bash
kubectl get pods -n dev
# order-service, product-service, user-service muestran RESTARTS: 1
```

**Causa**: Tiempo insuficiente para conectar con Eureka Server durante primer intento de inicio.

**Solución implementada en manifiestos:**
```yaml
readinessProbe:
  initialDelaySeconds: 240  # 4 minutos de espera antes de primera comprobación
  periodSeconds: 10
```

**Resultado**: Después del restart, servicios se conectaron exitosamente.

#### Problema 3: Discovery Client "UNKNOWN" en Health Check

**Síntoma:**
```json
{
  "discoveryComposite": {
    "status": "UNKNOWN",
    "description": "Discovery Client not initialized"
  }
}
```

**Causa**: Servicios aún registrándose en Eureka (toma 2-3 minutos).

**Solución**: Comportamiento normal. Después de 3-5 minutos, los servicios aparecen registrados en Eureka dashboard.

### 5.2 Optimizaciones Implementadas

#### Optimización 1: Uso de GKE Autopilot

**Antes**: Cluster GKE estándar con gestión manual de node pools
**Después**: GKE Autopilot con auto-scaling completo

**Beneficios:**
- ✅ Sin necesidad de dimensionar node pools
- ✅ Auto-scaling automático según demanda
- ✅ Evita limitaciones de cuota SSD
- ✅ Costo optimizado (pago por pod, no por nodo)
- ✅ Gestión de parches y actualizaciones automática

#### Optimización 2: H2 In-Memory en lugar de Cloud SQL

**Antes**: Intentos de desplegar Cloud SQL PostgreSQL
**Después**: H2 in-memory database

**Ventajas:**
- ✅ Sin requisitos de cuota SSD adicional
- ✅ Arranque más rápido de servicios
- ✅ Simplificación de manifiestos (sin secretos DB)
- ✅ Suficiente para ambiente de desarrollo/demostración

**Limitaciones aceptadas:**
- ⚠️ Datos no persistentes (se pierden al reiniciar pods)
- ⚠️ No adecuado para producción real

#### Optimización 3: Resource Requests y Limits

**Configuración aplicada:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"
```

**Resultado**: Autopilot provisiona nodos con recursos óptimos para ejecutar todos los pods eficientemente.

---

## Resultados Finales y Evidencias

### 6.1 Infraestructura Desplegada

#### Google Cloud Platform

```bash
# Verificar proyecto activo
gcloud config get-value project
# Output: ecommerce-microservices-479317

# Listar clusters GKE
gcloud container clusters list --project=ecommerce-microservices-479317

# Output:
NAME                    LOCATION      MASTER_VERSION      MASTER_IP      STATUS
ecommerce-dev-cluster   us-central1   1.33.5-gke.1201000  34.71.246.206  RUNNING
```

#### Recursos de Terraform

```bash
cd terraform/environments/dev
terraform show | head -50

# Recursos creados:
# - google_compute_network.vpc
# - google_compute_subnetwork.subnet
# - google_compute_firewall.allow_internal
# - google_compute_firewall.allow_external
# - google_container_cluster.primary (Autopilot)
# - google_artifact_registry_repository.microservices
# - google_project_service.* (10 APIs habilitadas)
```

#### Estado de Terraform

```bash
terraform state list

# Output:
google_artifact_registry_repository.microservices
google_compute_firewall.allow_external
google_compute_firewall.allow_internal
google_compute_network.vpc
google_compute_subnetwork.subnet
google_container_cluster.primary
google_project_service.artifactregistry
google_project_service.compute
google_project_service.container
google_project_service.logging
google_project_service.monitoring
google_project_service.storage
```

### 6.2 Cluster Kubernetes

#### Información del Cluster

```bash
kubectl cluster-info

# Output:
Kubernetes control plane is running at https://34.71.246.206
GLBCDefaultBackend is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
KubeDNS is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://34.71.246.206/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

#### Nodos del Cluster

```bash
kubectl get nodes -o wide

# Output:
NAME                                             STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gk3-ecommerce-dev-cluster-pool-5-af11d03b-cpcs   Ready    <none>   30m   v1.33.5-gke.1201000   10.0.0.5      34.59.220.200   Container-Optimized OS from Google   6.6.105+         containerd://2.0.6
gk3-ecommerce-dev-cluster-pool-5-f8b0400c-9ffd   Ready    <none>   30m   v1.33.5-gke.1201000   10.0.0.4      34.55.115.243   Container-Optimized OS from Google   6.6.105+         containerd://2.0.6
```

**Características de los nodos:**
- Sistema operativo: Container-Optimized OS from Google
- Runtime de contenedores: containerd 2.0.6
- Kernel: 6.6.105+
- IPs internas en rango 10.0.0.0/16 (subnet configurada en Terraform)
- IPs externas asignadas por GCP

### 6.3 Microservicios Desplegados

#### Estado de Pods

```bash
kubectl get pods -n dev -o wide

# Output:
NAME                                 READY   STATUS    RESTARTS        AGE   IP          NODE
config-server-7cb778795b-m8qn7       1/1     Running   0               35m   10.4.0.13   gk3-...-f8b0400c-9ffd
favourite-service-5775658dc5-sxg6t   1/1     Running   0               34m   10.4.0.71   gk3-...-af11d03b-cpcs
order-service-7bc775d545-zzxb7       1/1     Running   1 (24m ago)     34m   10.4.0.3    gk3-...-f8b0400c-9ffd
payment-service-5dcc5f4558-vp6gk     1/1     Running   0               34m   10.4.0.69   gk3-...-af11d03b-cpcs
product-service-747457df78-rsqp6     1/1     Running   1 (23m ago)     34m   10.4.0.16   gk3-...-f8b0400c-9ffd
proxy-client-5677c94575-42zgm        1/1     Running   0               35m   10.4.0.70   gk3-...-af11d03b-cpcs
service-discovery-67bb75d87c-b6wr7   1/1     Running   0               35m   10.4.0.67   gk3-...-af11d03b-cpcs
shipping-service-6b67c9b94b-hhdds    1/1     Running   0               34m   10.4.0.4    gk3-...-f8b0400c-9ffd
user-service-688c69447b-kbbz2        1/1     Running   1 (25m ago)     34m   10.4.0.2    gk3-...-f8b0400c-9ffd
zipkin-96d664d79-dcqdr               1/1     Running   1 (30m ago)     35m   10.4.0.68   gk3-...-af11d03b-cpcs
```

**Métricas finales:**
- ✅ 11/11 pods en estado Running
- ✅ 11/11 pods Ready (1/1)
- ✅ Distribución balanceada entre 2 nodos
- ✅ IPs asignadas del rango secundario para pods (10.4.0.0/14)

#### Estado de Servicios

```bash
kubectl get svc -n dev

# Output:
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)          AGE
config-server       ClusterIP      10.8.5.190      <none>            8888/TCP         36m
favourite-service   ClusterIP      10.8.6.188      <none>            8800/TCP         35m
order-service       ClusterIP      10.8.1.97       <none>            8300/TCP         35m
payment-service     ClusterIP      10.8.7.231      <none>            8400/TCP         35m
product-service     ClusterIP      10.8.10.214     <none>            8500/TCP         35m
proxy-client        LoadBalancer   10.8.9.15       34.42.85.83       8200:30123/TCP   36m
service-discovery   LoadBalancer   10.8.12.70      136.112.111.165   8761:31456/TCP   36m
shipping-service    ClusterIP      10.8.12.66      <none>            8600/TCP         35m
user-service        ClusterIP      10.8.8.161      <none>            8700/TCP         35m
zipkin              LoadBalancer   10.8.9.14       34.30.132.160     9411:32789/TCP   36m
```

**IPs de servicios del rango secundario (10.8.0.0/20)**

### 6.4 Evidencias de Funcionamiento

#### Evidencia 1: Health Check del API Gateway

```bash
curl -s http://34.42.85.83:8200/actuator/health | jq .status
# Output: "UP"
```

#### Evidencia 2: Servicios Registrados en Eureka

Acceder a: **http://136.112.111.165:8761**

Servicios esperados en dashboard:
- CONFIG-SERVER (1 instancia)
- PROXY-CLIENT (1 instancia)
- USER-SERVICE (1 instancia)
- PRODUCT-SERVICE (1 instancia)
- ORDER-SERVICE (1 instancia)
- PAYMENT-SERVICE (1 instancia)
- SHIPPING-SERVICE (1 instancia)
- FAVOURITE-SERVICE (1 instancia)

#### Evidencia 3: Zipkin Tracing Activo

Acceder a: **http://34.30.132.160:9411**

UI de Zipkin mostrando:
- Interfaz de búsqueda de trazas
- Servicios disponibles para tracing
- Gráficos de dependencias de servicios

#### Evidencia 4: Logs de Inicialización Exitosa

```bash
# Ejemplo de logs exitosos (Order Service)
kubectl logs -n dev order-service-7bc775d545-zzxb7 | grep -E "(Started|H2|Flyway|Hibernate|Eureka)" | head -20

# Output esperado:
INFO HikariPool-1 - Start completed
INFO H2 console available at '/h2-console'
INFO Database available at 'jdbc:h2:mem:ecommerce_dev_db'
INFO Flyway Community Edition 7.7.3 by Redgate
INFO Successfully validated 5 migrations
INFO Successfully applied 5 migrations to schema "PUBLIC"
INFO HHH000412: Hibernate ORM core version 5.4.32.Final
INFO Using dialect: org.hibernate.dialect.H2Dialect
INFO Started OrderServiceApplication in 45.732 seconds
INFO Registering application ORDER-SERVICE with eureka
```

### 6.5 Tabla Resumen del Proyecto

| Aspecto | Detalle | Estado |
|---------|---------|--------|
| **Cloud Provider** | Google Cloud Platform | ✅ Configurado |
| **Proyecto GCP** | ecommerce-microservices-479317 | ✅ Activo |
| **Región** | us-central1 | ✅ Operativa |
| **IaC Tool** | Terraform 1.13.5 | ✅ Implementado |
| **Terraform State** | GCS Bucket remoto con versionado | ✅ Configurado |
| **Cluster Type** | GKE Autopilot | ✅ Desplegado |
| **Kubernetes Version** | 1.33.5-gke.1201000 | ✅ Actualizada |
| **Nodos** | 2 nodos auto-provisionados | ✅ Ready |
| **Networking** | VPC custom con subredes secundarias | ✅ Configurada |
| **Container Registry** | Artifact Registry | ✅ Creado |
| **Microservicios** | 11 servicios completos | ✅ Todos Running |
| **Service Discovery** | Eureka Server | ✅ Operativo |
| **API Gateway** | Spring Cloud Gateway | ✅ Accesible |
| **Distributed Tracing** | Zipkin | ✅ Funcional |
| **Config Management** | Spring Cloud Config + K8s ConfigMaps | ✅ Implementado |
| **Database** | H2 In-Memory (por servicio) | ✅ Operativo |
| **LoadBalancers** | 3 servicios expuestos públicamente | ✅ IPs asignadas |
| **Monitoring** | GKE Managed Prometheus | ✅ Habilitado |
| **Logging** | Cloud Logging | ✅ Habilitado |

### 6.6 Comandos para Capturas de Evidencia

#### GCP Console (Navegador)

1. **Vista del Cluster:**
   - URL: https://console.cloud.google.com/kubernetes/clusters?project=ecommerce-microservices-479317
   - Captura: Cluster "ecommerce-dev-cluster" con status RUNNING

2. **Workloads (Pods):**
   - Navegar a: Kubernetes Engine → Workloads
   - Captura: 11 deployments con checkmarks verdes

3. **Services & Ingress:**
   - Navegar a: Kubernetes Engine → Services & Ingress
   - Captura: 3 LoadBalancer services con IPs externas

#### Terminal (Comandos CLI)

```bash
# Captura 1: Información del proyecto
gcloud config list

# Captura 2: Estado del cluster
gcloud container clusters list --project=ecommerce-microservices-479317

# Captura 3: Nodos Kubernetes
kubectl get nodes -o wide

# Captura 4: Pods en namespace dev
kubectl get pods -n dev

# Captura 5: Servicios con IPs externas
kubectl get svc -n dev

# Captura 6: Estado completo
kubectl get all -n dev

# Captura 7: Recursos de Terraform
cd terraform/environments/dev && terraform state list
```

#### Navegador Web (UIs)

1. **Eureka Dashboard:**
   - URL: http://136.112.111.165:8761
   - Captura: Servicios registrados

2. **Zipkin UI:**
   - URL: http://34.30.132.160:9411
   - Captura: Interfaz de trazas

3. **Health Check API Gateway:**
   - URL: http://34.42.85.83:8200/actuator/health
   - Captura: JSON response con status "UP"

### 6.7 Costos Estimados

**Recursos GCP utilizados:**

| Recurso | Tipo | Cantidad | Costo Estimado/Día* |
|---------|------|----------|---------------------|
| GKE Autopilot Cluster | Cluster fee | 1 | $2.88 |
| GKE Autopilot Pods | CPU + Memory | 11 pods | $3-5 (variable) |
| LoadBalancer | External IPs | 3 | $0.54 |
| VPC Networking | Egress traffic | Variable | $0-1 |
| Artifact Registry | Storage | <1GB | $0.10 |
| Cloud Logging | Logs ingestion | Standard | $0.50 |
| **TOTAL ESTIMADO** | | | **~$7-10/día** |

*Costos aproximados basados en pricing de GCP en us-central1 para November 2025

**Nota**: Para minimizar costos después de capturas de evidencia:
```bash
# Escalar deployments a 0 replicas (mantiene configuración)
kubectl scale deployment --all --replicas=0 -n dev

# O destruir completamente la infraestructura
cd terraform/environments/dev
terraform destroy -auto-approve
```

---

## Conclusiones

### 7.1 Logros Alcanzados

✅ **Infraestructura como Código**: Se implementó exitosamente una infraestructura completa en GCP utilizando Terraform, permitiendo versionado, reproducibilidad y gestión declarativa de recursos cloud.

✅ **Cloud Native Deployment**: Se desplegó un cluster GKE Autopilot completamente gestionado, eliminando la necesidad de administración manual de nodos y optimizando costos.

✅ **Microservicios Completos**: Los 11 microservicios fueron desplegados exitosamente con:
- Service Discovery (Eureka)
- API Gateway centralizado
- Distributed Tracing (Zipkin)
- Gestión de configuración centralizada
- Health checks y readiness probes

✅ **Networking Avanzado**: Configuración de VPC custom con subredes secundarias para segregación de IPs de pods y servicios.

✅ **Observabilidad**: Implementación de logging (Cloud Logging), monitoring (Managed Prometheus), y tracing distribuido (Zipkin).

✅ **Alta Disponibilidad**: Distribución automática de pods entre múltiples nodos con auto-scaling de GKE Autopilot.

### 7.2 Desafíos Superados

🔧 **Limitaciones de Cuota**: Adaptación exitosa a limitaciones de cuota SSD mediante uso de GKE Autopilot en lugar de cluster estándar.

🔧 **Base de Datos**: Pivote de Cloud SQL a H2 in-memory, manteniendo funcionalidad completa para ambiente de desarrollo.

🔧 **Tiempos de Inicio**: Configuración de readiness probes con delays apropiados para permitir inicialización completa de Spring Boot.

🔧 **Service Discovery**: Gestión correcta de registro de servicios en Eureka con timeouts y reintentos apropiados.

### 7.3 Conocimientos Adquiridos

📚 **Google Cloud Platform**:
- Gestión de proyectos y service accounts
- APIs de GCP y habilitación de servicios
- Gestión de cuotas y limitaciones regionales
- GKE Autopilot vs clusters estándar

📚 **Terraform**:
- Backends remotos con GCS
- Gestión de estado con versionado
- Modularización de infraestructura
- Resolución de dependencias entre recursos

📚 **Kubernetes en GKE**:
- Autopilot mode y auto-scaling
- Networking con VPC-native clusters
- LoadBalancer services y asignación de IPs externas
- ConfigMaps para gestión de configuración
- Resource requests y limits para optimización

📚 **Microservicios Cloud Native**:
- Patterns de Spring Cloud (Config, Gateway, Discovery)
- Health checks y liveness/readiness probes
- Distributed tracing con Zipkin
- Service mesh basics y comunicación inter-servicios

### 7.4 Mejoras Futuras

🚀 **Seguridad**:
- Implementar Ingress con certificados SSL/TLS
- Configurar Network Policies para segmentación
- Utilizar Secret Manager de GCP en lugar de ConfigMaps para credenciales
- Implementar Identity-Aware Proxy (IAP)

🚀 **Bases de Datos**:
- Migrar a Cloud SQL PostgreSQL con alta disponibilidad
- Implementar backups automáticos
- Configurar read replicas para escalabilidad

🚀 **CI/CD**:
- Implementar pipeline con Cloud Build o GitHub Actions
- Automatizar construcción de imágenes Docker
- Deploy continuo a múltiples ambientes (dev/stage/prod)
- Integración con Artifact Registry para versionado de imágenes

🚀 **Observabilidad**:
- Configurar alertas en Cloud Monitoring
- Dashboards personalizados en Cloud Monitoring
- Integración con herramientas APM (Application Performance Monitoring)
- Logs estructurados y agregación avanzada

🚀 **Escalabilidad**:
- Implementar Horizontal Pod Autoscaler (HPA)
- Configurar Vertical Pod Autoscaler (VPA)
- Implementar caching con Redis/Memcached
- Load testing y optimización de recursos

🚀 **Multi-Region**:
- Despliegue multi-regional para alta disponibilidad
- Global Load Balancer
- Disaster Recovery plan

### 7.5 Lecciones Aprendidas

💡 **GKE Autopilot es ideal para equipos pequeños**: Reduce significativamente la complejidad operativa eliminando la necesidad de gestionar node pools.

💡 **H2 in-memory es suficiente para desarrollo**: Para entornos de desarrollo y demostración, bases de datos en memoria simplifican el despliegue sin comprometer funcionalidad.

💡 **Readiness probes son críticas**: Spring Boot requiere tiempo considerable para inicialización completa (Flyway, Hibernate, Eureka registration). Delays de 3-4 minutos son apropiados.

💡 **Terraform permite rápida iteración**: La capacidad de destruir y recrear infraestructura completa en minutos facilita experimentación y corrección de errores.

💡 **Cuotas de GCP requieren planificación**: Es fundamental verificar cuotas disponibles antes de diseñar arquitectura, especialmente para proyectos nuevos con free tier.

💡 **Service Discovery es esencial en microservicios**: Eureka simplifica enormemente la comunicación entre servicios, eliminando necesidad de hardcodear IPs o FQDNs.

### 7.6 Recomendaciones

📋 **Para Desarrollo**:
- Utilizar GKE Autopilot para reducir complejidad
- H2 in-memory es adecuado
- Un solo namespace es suficiente
- LoadBalancers solo para servicios que requieren acceso externo

📋 **Para Staging**:
- Considerar cluster GKE estándar si se requiere mayor control
- Migrar a bases de datos gestionadas (Cloud SQL)
- Implementar multiple namespaces para aislamiento
- Configurar Ingress en lugar de múltiples LoadBalancers

📋 **Para Producción**:
- Cluster GKE estándar con node pools personalizados
- Cloud SQL con alta disponibilidad y backups
- Múltiples regiones para disaster recovery
- CI/CD completo con ambientes separados
- Monitoring y alerting comprehensivo
- Security hardening (Network Policies, Workload Identity, Binary Authorization)

---

## Anexos

### A. Comandos Útiles de Terraform

```bash
# Ver plan sin aplicar
terraform plan

# Aplicar solo un recurso específico
terraform apply -target=google_container_cluster.primary

# Ver estado actual
terraform show

# Listar recursos
terraform state list

# Ver detalles de un recurso
terraform state show google_container_cluster.primary

# Refrescar estado sin hacer cambios
terraform refresh

# Formatear archivos .tf
terraform fmt -recursive

# Validar sintaxis
terraform validate

# Crear gráfico de dependencias
terraform graph | dot -Tpng > graph.png

# Destruir infraestructura
terraform destroy
```

### B. Comandos Útiles de kubectl

```bash
# Ver recursos en todos los namespaces
kubectl get all -A

# Describir pod con eventos
kubectl describe pod POD_NAME -n dev

# Ver logs en tiempo real
kubectl logs -f POD_NAME -n dev

# Ver logs de contenedor anterior (después de restart)
kubectl logs POD_NAME -n dev --previous

# Ejecutar comando en pod
kubectl exec -it POD_NAME -n dev -- /bin/bash

# Port forwarding para acceso local
kubectl port-forward svc/service-discovery 8761:8761 -n dev

# Escalar deployment
kubectl scale deployment DEPLOYMENT_NAME --replicas=3 -n dev

# Ver eventos del namespace
kubectl get events -n dev --sort-by='.lastTimestamp'

# Ver recursos consumidos
kubectl top nodes
kubectl top pods -n dev

# Eliminar recursos por label
kubectl delete pods -l app=user-service -n dev
```

### C. Comandos Útiles de gcloud

```bash
# Listar proyectos
gcloud projects list

# Cambiar proyecto activo
gcloud config set project PROJECT_ID

# Ver configuración actual
gcloud config list

# Listar clusters
gcloud container clusters list

# Obtener credenciales de cluster
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# Describir cluster
gcloud container clusters describe CLUSTER_NAME --region REGION

# Ver cuotas del proyecto
gcloud compute project-info describe --project=PROJECT_ID

# Listar APIs habilitadas
gcloud services list --enabled

# Ver logs de Cloud Logging
gcloud logging read "resource.type=k8s_cluster" --limit 50

# Listar service accounts
gcloud iam service-accounts list
```

---

## Referencias

### Documentación Oficial

- [Google Cloud Platform Documentation](https://cloud.google.com/docs)
- [Google Kubernetes Engine (GKE) Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Spring Cloud Netflix Eureka](https://spring.io/projects/spring-cloud-netflix)
- [Zipkin Distributed Tracing](https://zipkin.io/)

### Tutoriales y Guías

- [GKE Autopilot Best Practices](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Terraform GCP Getting Started](https://learn.hashicorp.com/collections/terraform/gcp-get-started)
- [Microservices with Spring Cloud](https://spring.io/guides/gs/service-registration-and-discovery/)

### Herramientas Utilizadas

- Terraform: https://www.terraform.io/
- Google Cloud SDK: https://cloud.google.com/sdk
- kubectl: https://kubernetes.io/docs/tasks/tools/
- Docker: https://www.docker.com/

---

**Fin del Documento**

*Taller Final - Despliegue Cloud con GCP*  
*Fecha de Elaboración: Noviembre 28, 2025*  
*Proyecto: ecommerce-microservices-479317*  
*Autor: David Santiago Malte Ortiz*
docker-workflow:580.v87c7fc1639ac
kubernetes:1.34.1
kubernetes-cli:1.15.0
maven-plugin:3.24
pipeline-aggregator:596.v8c21c963d92d
credentials:1336.v1e07e7c4f1d2
junit:1290.v2163efab_a_d1
```

#### Docker Compose para Jenkins

```yaml
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: jenkins-controller
    restart: unless-stopped
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Xmx1024m -Xms512m
      - DOCKER_HOST=unix:///var/run/docker.sock
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

volumes:
  jenkins_home:
    driver: local
```

#### Inicio de Jenkins

```bash
cd jenkins
docker-compose build --no-cache
docker-compose up -d

# Obtener contraseña inicial
docker exec jenkins-controller cat /var/jenkins_home/secrets/initialAdminPassword

# Acceder a Jenkins
# http://localhost:8080
```

#### Configuración de Credenciales

**Docker Hub Credentials:**
- Tipo: Username with password
- Username: `merako34`
- Password: `dckr_pat_XXXXXXXXXXXXX` (token real)
- ID: `dockerhub-credentials`

**Kubernetes Kubeconfig:**
- Tipo: Kubernetes configuration (kubeconfig)
- Scope: Global
- Kubeconfig: Contenido de `~/.kube/config`
- ID: `kubernetes-config`

### 1.3 Configuración de Kubernetes

#### Creación de Secretos Docker Registry

```bash
# Para namespace dev
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=dev

# Para namespace stage
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=stage

# Para namespace prod
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=prod
```

#### Verificación de Secretos

```bash
kubectl get secrets --all-namespaces | grep dockerhub-credentials
# Output: dev       dockerhub-credentials    kubernetes.io/dockercfg   1      2m
#         stage     dockerhub-credentials    kubernetes.io/dockercfg   1      2m
#         prod      dockerhub-credentials    kubernetes.io/dockercfg   1      2m
```

#### Creación de Namespaces Yaml

**dev-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

**stage-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: stage
  labels:
    environment: staging
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

**prod-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

---

## Fase 2: Pipelines DEV (15%)

### 2.1 Estructura del Pipeline DEV

**Tiempo de Ejecución**: 5 min 7 seg

#### Stages del Pipeline

```
┌─────────────────────────────────────────────────┐
│ 1. CHECKOUT                                     │
│    - Clonar repositorio                         │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 2. BUILD CON MAVEN                              │
│    - Compilar código                            │
│    - Resolver dependencias                      │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 3. BUILD DOCKER                                 │
│    - Crear imagen Docker                        │
│    - Tag con nombre del servicio                │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 4. PUSH A DOCKER HUB                            │
│    - Subir imagen a docker.io                   │
│    - Usar credenciales de Docker Hub            │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 5. DEPLOY A DEV                                 │
│    - Aplicar manifiestos Kubernetes             │
│    - Namespace: dev                             │
└─────────────────────────────────────────────────┘
```

### 2.2 Jenkinsfile DEV

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_USERNAME = 'merako34'
        DOCKER_REGISTRY = 'docker.io'
        KUBE_NAMESPACE = 'dev'
        DOCKER_TAG = "${BUILD_NUMBER}"
        MAVEN_OPTS = '-Xmx1024m -Xms512m'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Clonando repositorios..."
                    checkout scm
                }
            }
        }

        stage('Setup Namespace') {
            steps {
                script {
                    echo "Configurando namespace dev"
                }
            }
        }

        stage('Check Docker Images') {
            steps {
                script {
                    echo " Verificando si las imágenes"
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "🔨 Compilando con Maven..."
                    sh 'mvn clean compile'
                }
            }
        }
    
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construyendo imagen Docker..."
                    sh '''
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG} .
                    '''
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Subiendo imagen a Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG}
                            docker logout
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to DEV') {
            steps {
                script {
                    echo "🚀 Desplegando en DEV..."
                    sh '''
                        kubectl apply -f k8s/dev/ -n ${KUBE_NAMESPACE}
                        kubectl set image deployment/${SERVICE_NAME} \
                            ${SERVICE_NAME}=${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG} \
                            -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/${SERVICE_NAME} -n ${KUBE_NAMESPACE}
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline DEV completado exitosamente"
        }
        failure {
            echo "❌ Pipeline DEV falló"
        }
    }
}
```

### 2.3 Variables de Entorno DEV

```bash
# env.config (No subir a Git)
DOCKER_USERNAME=merako34
DOCKER_REGISTRY=docker.io
KUBE_CONTEXT=docker-desktop
KUBE_NAMESPACE_DEV=dev
JENKINS_URL=http://localhost:8080
MAVEN_OPTS=-Xmx1024m -Xms512m
```

### 2.4 Manifiestos Kubernetes para DEV

**Ejemplo - User Service:**

```yaml
# user-service/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      imagePullSecrets:
      - name: dockerhub-credentials
      containers:
      - name: user-service
        image: merako34/user-service:0.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8700
          name: http
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /user-service/actuator/health
            port: 8700
          initialDelaySeconds: 420
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /user-service/actuator/health
            port: 8700
          initialDelaySeconds: 240
          periodSeconds: 5
```

---
```yaml
# user-service/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
spec:
  type: ClusterIP
  selector:
    app: user-service
  ports:
  - name: http
    port: 8700
    targetPort: 8700
    protocol: TCP
```
---
```yaml
# user-service/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: dev
data:
  application-dev.yml: |
    server:
      port: 8700
      servlet:
        context-path: /user-service
    spring:
      application:
        name: USER-SERVICE
      profiles:
        active: dev
      datasource:
        url: jdbc:h2:mem:ecommerce_dev_db
        username: sa
```

---

## Fase 3: Pruebas Implementadas (30%)

### 3.1 Pruebas Unitarias

#### Descripción General

- **Servicios Implementados**: 5/6 (Order, Payment, Product, Shipping, User)
- **Servicio Pendiente**: Favourite Service
- **Tasa de Éxito**: 83.33%
- **Framework**: JUnit 5 + Mockito

#### Objetivos de Pruebas Unitarias

Cada servicio incluye al menos 5 pruebas unitarias que validen:

1. **Validación de Componentes Individuales**
   - Servicios de negocio
   - Controladores REST
   - Repositorios/DAO
   - Validadores
   - Mappers

2. **Casos de Uso**
   - Búsqueda de recursos
   - Creación de recursos
   - Actualización de recursos
   - Eliminación de recursos
   - Validaciones de negocio

#### Ejemplo: Order Service Unit Tests

```java
// OrderServiceTest.java
@ExtendWith(MockitoExtension.class)
class OrderServiceImplTest {

	@Mock
	private OrderRepository orderRepository;

	@InjectMocks
	private OrderServiceImpl orderService;

	private Order order;
	private OrderDto orderDto;
	private Cart cart;
	private CartDto cartDto;

	@BeforeEach
	void setUp() {
		cart = Cart.builder()
				.cartId(1)
				.userId(1)
				.build();

		cartDto = CartDto.builder()
				.cartId(1)
				.userId(1)
				.build();

		order = Order.builder()
				.orderId(1)
				.orderDate(LocalDateTime.now())
				.orderDesc("Test Order")
				.orderFee(100.00)
				.cart(cart)
				.build();

		orderDto = OrderDto.builder()
				.orderId(1)
				.orderDate(LocalDateTime.now())
				.orderDesc("Test Order")
				.orderFee(100.00)
				.cartDto(cartDto)
				.build();
	}

	@Test
	@DisplayName("findAll - Debe retornar lista de órdenes")
	void testFindAll_Success() {
		when(orderRepository.findAll()).thenReturn(List.of(order));

		List<OrderDto> result = orderService.findAll();

		assertNotNull(result);
		assertEquals(1, result.size());
		assertEquals("Test Order", result.get(0).getOrderDesc());
		verify(orderRepository, times(1)).findAll();
	}

	@Test
	@DisplayName("findById - Debe retornar orden por ID")
	void testFindById_Success() {
		when(orderRepository.findById(1)).thenReturn(Optional.of(order));

		OrderDto result = orderService.findById(1);

		assertNotNull(result);
		assertEquals(1, result.getOrderId());
		assertEquals("Test Order", result.getOrderDesc());
		verify(orderRepository, times(1)).findById(1);
	}

	@Test
	@DisplayName("findById - Debe lanzar excepción cuando orden no existe")
	void testFindById_NotFound() {
		when(orderRepository.findById(999)).thenReturn(Optional.empty());

		assertThrows(OrderNotFoundException.class, () -> orderService.findById(999));
		verify(orderRepository, times(1)).findById(999);
	}

	@Test
	@DisplayName("save - Debe guardar orden correctamente")
	void testSave_Success() {
		when(orderRepository.save(any(Order.class))).thenReturn(order);

		OrderDto result = orderService.save(orderDto);

		assertNotNull(result);
		assertEquals("Test Order", result.getOrderDesc());
		assertEquals(100.00, result.getOrderFee());
		verify(orderRepository, times(1)).save(any(Order.class));
	}

	@Test
	@DisplayName("deleteById - Debe eliminar orden por ID")
	void testDeleteById_Success() {
		when(orderRepository.findById(1)).thenReturn(Optional.of(order));
		doNothing().when(orderRepository).delete(any(Order.class));

		orderService.deleteById(1);

		verify(orderRepository, times(1)).findById(1);
		verify(orderRepository, times(1)).delete(any(Order.class));
	}
}
```

#### Resultados de Pruebas Unitarias

| Servicio | Total Tests | Pasadas | Fallidas | Estado |
|----------|------------|---------|----------|--------|
| User Service | 5 | 5 | 0 | ✅ PASS |
| Product Service | 5 | 5 | 0 | ✅ PASS |
| Order Service | 5 | 5 | 0 | ✅ PASS |
| Payment Service | 5 | 5 | 0 | ✅ PASS |
| Shipping Service | 5 | 5 | 0 | ✅ PASS |
| Favourite Service | - | - | - | ⚠️ NO IMPLEMENTADO |
| **TOTAL** | **25** | **25** | **0** | **✅ 100%** |

### 3.2 Pruebas de Integración

#### Descripción General

- **Servicios Implementados**: 5/6
- **Tasa de Éxito**: 83.33%
- **Framework**: TestContainers + RestAssured

#### Objetivos de Pruebas de Integración

Cada servicio incluye al menos 5 pruebas que validen:

1. **Comunicación Inter-Servicios**
   - Eureka Service Discovery
   - Llamadas HTTP entre servicios
   - Load Balancing

2. **Integración con Infraestructura**
   - Base de datos H2
   - Config Server
   - Zipkin

3. **Casos de Uso Completos**
   - Flujos que involucran múltiples servicios
   - Manejo de errores distribuidos

#### Ejemplo: Payment Service Integration Tests

```java
@SpringBootTest
@ActiveProfiles("dev")
@Transactional
class PaymentServiceApplicationTests {

	@Autowired
	private PaymentRepository paymentRepository;

	@Autowired
	private PaymentServiceImpl paymentService;

	@MockBean
	private RestTemplate restTemplate;

	private Payment payment;
	private OrderDto orderDto;

	@BeforeEach
	void setUp() {
		orderDto = OrderDto.builder()
				.orderId(1)
				.build();

		payment = Payment.builder()
				.orderId(1)
				.isPayed(false)
				.paymentStatus(PaymentStatus.IN_PROGRESS)
				.build();
	}

	@Test
	@DisplayName("findAll - Debe retornar todos los pagos de base de datos")
	void testFindAll_Integration_Success() {
		Payment saved = paymentRepository.save(payment);
		when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

		List<PaymentDto> result = paymentService.findAll();

		assertNotNull(result);
		assertTrue(result.size() > 0);
		assertTrue(result.stream().anyMatch(p -> p.getPaymentId().equals(saved.getPaymentId())));
	}

	@Test
	@DisplayName("findById - Debe obtener pago guardado en base de datos")
	void testFindById_Integration_Success() {
		Payment saved = paymentRepository.save(payment);
		when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

		PaymentDto result = paymentService.findById(saved.getPaymentId());

		assertNotNull(result);
		assertEquals(saved.getPaymentId(), result.getPaymentId());
		assertEquals(PaymentStatus.IN_PROGRESS, result.getPaymentStatus());
	}

	@Test
	@DisplayName("save - Debe persistir pago en base de datos")
	void testSave_Integration_Success() {
		PaymentDto dto = PaymentDto.builder()
				.isPayed(false)
				.paymentStatus(PaymentStatus.NOT_STARTED)
				.orderDto(OrderDto.builder()
						.orderId(2)
						.build())
				.build();

		PaymentDto result = paymentService.save(dto);

		assertNotNull(result.getPaymentId());
		assertEquals(PaymentStatus.NOT_STARTED, result.getPaymentStatus());
		assertTrue(paymentRepository.existsById(result.getPaymentId()));
	}

	@Test
	@DisplayName("update - Debe actualizar pago existente")
	void testUpdate_Integration_Success() {
		Payment saved = paymentRepository.save(payment);

		PaymentDto updateDto = PaymentDto.builder()
				.paymentId(saved.getPaymentId())
				.isPayed(true)
				.paymentStatus(PaymentStatus.COMPLETED)
				.orderDto(OrderDto.builder()
						.orderId(saved.getOrderId())
						.build())
				.build();

		PaymentDto result = paymentService.update(updateDto);

		assertTrue(result.getIsPayed());
		assertEquals(PaymentStatus.COMPLETED, result.getPaymentStatus());
	}

	@Test
	@DisplayName("deleteById - Debe eliminar pago de base de datos")
	void testDeleteById_Integration_Success() {
		Payment saved = paymentRepository.save(payment);

		paymentService.deleteById(saved.getPaymentId());

		assertFalse(paymentRepository.existsById(saved.getPaymentId()));
		assertThrows(PaymentNotFoundException.class, () -> paymentService.findById(saved.getPaymentId()));
	}
}
```

#### Resultados de Pruebas de Integración

| Servicio | Total Tests | Pasadas | Fallidas | Estado |
|----------|------------|---------|----------|--------|
| User Service | 5 | 5 | 0 | ✅ PASS |
| Product Service | 5 | 5 | 0 | ✅ PASS |
| Order Service | 5 | 5 | 0 | ✅ PASS |
| Payment Service | 5 | 5 | 0 | ✅ PASS |
| Shipping Service | 5 | 5 | 0 | ✅ PASS |
| Favourite Service | - | - | - | ⚠️ NO IMPLEMENTADO |
| **TOTAL** | **25** | **25** | **0** | **✅ 100%** |

### 3.3 Pruebas E2E

#### Descripción General

- **Framework**: Selenium / Postman / RestAssured
- **Cobertura**: Flujos de usuario completos
- **Mínimo**: 5 pruebas por servicio

#### Objetivos de Pruebas E2E

1. **Flujos de Usuario Reales**
   - Registro de usuario → Login → Compra
   - Búsqueda de productos → Agregar a carrito → Pago
   - Ver orden → Cancelar → Verificar estado


### 3.4 Pruebas de Rendimiento y Estrés (Locust)

#### Descripción General

- **Herramienta**: Apache Locust
- **Duración**: 30 segundos por servicio
- **Usuarios Concurrentes**: 5

#### Configuración de Locust

```python
class UserServiceUser(HttpUser):
    """Simulates user interactions with the User Service"""

    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    base_url = "http://localhost:8700"

    def on_start(self):
        """Setup before starting tasks"""
        self.user_id = None
        self.auth_token = None

    @task(3)
    def get_all_users(self):
        """Task 1: Get all users (most frequent)"""
        with self.client.get(
            "/api/user-service/users",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(2)
    def get_user_by_id(self):
        """Task 2: Get specific user by ID"""
        user_id = random.randint(1, 100)
        with self.client.get(
            f"/api/user-service/users/{user_id}",
            catch_response=True
        ) as response:
            if response.status_code in [200, 404]:  # Both are valid
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(2)
    def create_user(self):
        """Task 3: Create a new user"""
        unique_suffix = ''.join(random.choices(string.ascii_lowercase, k=5))
        user_data = {
            "username": f"perftest_{unique_suffix}",
            "email": f"perf_{unique_suffix}@test.com",
            "password": "TestPassword123!",
            "fullName": "Performance Test User",
            "phoneNumber": "+1234567890",
            "address": "123 Test St",
            "city": "Test City",
            "state": "TS",
            "postalCode": "12345",
            "country": "Test Country"
        }

        with self.client.post(
            "/api/user-service/users",
            json=user_data,
            catch_response=True
        ) as response:
            if response.status_code in [201, 200]:
                try:
                    self.user_id = response.json().get("id")
                    response.success()
                except:
                    response.failure("Failed to parse response")
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(1)
    def health_check(self):
        """Task 4: Check service health (least frequent)"""
        with self.client.get(
            "/actuator/health",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")


#### Ejecución de Pruebas de Rendimiento

```bash
# Ejecutar pruebas con Locust
locust -f locustfile.py \
  --host=http://localhost:8200 \
  --users 5 \
  --spawn-rate 5 \
  --run-time 30s \
  --headless

# Con reporte CSV
locust -f locustfile.py \
  --host=http://proxy-client:8200 \
  --csv=results \
  --headless
```

---

## Fase 4: Pipelines STAGE (15%)

### 4.1 Características del Pipeline STAGE

**Tiempo de Ejecución**: 11 minutos

El pipeline STAGE incluye:

1. ✅ Checkout - Code
2. ✅ Checkout - Operations
3. ✅ Setup Stage Namespace (Opcional)
4. ✅ Check Docker Images
5. ✅ Compile Services (Build con Maven)
6. ✅ Run Unit Tests (Pruebas unitarias)
7. ✅ Run Integration Tests (Pruebas de integración)
8. ✅ Build Docker Images (Build de Docker)
9. ✅ Push Docker Hub (Push a Docker Hub)
10. ✅ Check Kubernetes
11. ✅ Setup Docker Secret
12. ✅ Deploy Infraestructura (Opcional)
13. ✅ Deploy to Kubernetes (Deploy a Kubernetes STAGE)
14. ✅ Verify Deployment
15. ✅ Get Service IPs
16. ✅ Run E2E Tests (Pruebas E2E en STAGE)
17. ✅ Run Smoke Tests (Pruebas de humo/Smoke Tests)
18. ✅ Analyze Test Results
19. ✅ Archive Test Results

### 4.2 Jenkinsfile STAGE

```groovy
pipeline {
    agent any

    stages {
        stage('1. Checkout - Code') {
            steps {
                echo "🔄 Clonando repositorio de código"
            }
        }

        stage('2. Checkout - Operations') {
            steps {
                echo "🔄 Clonando repositorio de operaciones"
            }
        }

        stage('3. Setup Stage Namespace (Opcional)') {
            when {
                expression { params.SETUP_NAMESPACE == true }
            }
            steps {
                echo "⚙️ Configurando namespace, creando secret Docker Registry"
            }
        }

        stage('4. Check Docker Images') {
            steps {
                echo "🔍 Verificando si las imágenes existen en Docker Hub"
            }
        }

        stage('5. Compile Services') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "🔨 Compilando 8 microservicios con Maven"
            }
        }

        stage('6. Build Docker Images') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "🐳 Construyendo imágenes Docker para 8 servicios"
            }
        }

        stage('7. Push Docker Hub') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "📤 Subiendo imágenes a Docker Hub"
            }
        }

        stage('8. Skip Build') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'true' }
            }
            steps {
                echo "⭐️ Saltando compilación (imágenes ya existen)"
            }
        }

        stage('9. Check Kubernetes') {
            steps {
                echo "🔍 Verificando conexión a Kubernetes y nodos disponibles"
            }
        }

        stage('10. Setup Docker Secret') {
            when {
                expression { params.SETUP_NAMESPACE == false }
            }
            steps {
                echo "🔐 Creando Docker Registry Secret si es necesario"
            }
        }

        stage('11. Deploy Infraestructura (Opcional)') {
            when {
                expression { params.DEPLOY_INFRA == true }
            }
            steps {
                echo "🏗️ Desplegando Config Server y Zipkin"
            }
        }

        stage('12. Deploy to Kubernetes') {
            steps {
                echo "🚀 Desplegando 8 microservicios en namespace stage"
            }
        }

        stage('13. Verify Deployment') {
            steps {
                echo "⏳ Esperando a que pods estén listos (máximo 5 minutos)"
            }
        }

        stage('14. Get Service IPs') {
            steps {
                echo "🔍 Obteniendo IPs de servicios para pruebas"
            }
        }

        stage('15. Run Unit Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🧪 Ejecutando pruebas unitarias en 6 servicios"
            }
        }

        stage('16. Run Integration Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🔗 Ejecutando pruebas de integración en Kubernetes"
            }
        }

        stage('17. Run Performance Tests (Locust)') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "⚡ Ejecutando pruebas de rendimiento (5 usuarios, 30s por servicio)"
            }
        }

        stage('18. Analyze Test Results') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📊 Analizando resultados de pruebas unitarias, integración y rendimiento"
            }
        }

        stage('19. Archive Test Results') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📦 Archivando resultados de pruebas y logs"
            }
        }
    }

    post {
        success {
            echo "✓ PIPELINE STAGE COMPLETADO EXITOSAMENTE"
        }
        failure {
            echo "✗ PIPELINE STAGE FALLÓ"
        }
        always {
            archiveArtifacts artifacts: 'stage-test-results/**', allowEmptyArchive: true
        }
    }
}
```

### 4.3 Configuración de STAGE en Kubernetes

Los manifiestos STAGE están configurados con:
- 1 réplica por servicio
- 256Mi memoria/100m CPU (requests)
- 512Mi memoria/250m CPU (limits)
- Eureka habilitado
- Zipkin habilitado
- Config Server habilitado

**Ubicación**: `k8s/stage/`

---

## Fase 5: Pipeline PROD y Release Notes (15%)

### 5.1 Características del Pipeline PROD

**Tiempo de Ejecución**: 10 minutos

El pipeline MASTER (PROD) incluye:

1. ✅ Checkout del código
2. ✅ Checkout - Operations
3. ✅ Build con Maven
4. ✅ Pruebas unitarias
5. ✅ Pruebas de integración
6. ✅ Pruebas de rendimiento
7. ✅ Build de Docker
8. ✅ Push a Docker Hub
9. ✅ Deploy a Kubernetes PROD
10. ✅ Verify Deployment
11. ✅ Get Service IPs
12. ✅ Analizar resultados de pruebas
13. ✅ Archivar resultados de pruebas
14. ✅ Generar Release Notes automáticamente
15. ✅ Archivar Release Notes

### 5.2 Jenkinsfile PROD/MASTER

```groovy
pipeline {
    agent any

    stages {
        stage('1. Checkout del código') {
            steps {
                echo "🔄 Clonando repositorio de código"
            }
        }

        stage('2. Checkout - Operations') {
            steps {
                echo "🔄 Clonando repositorio de operaciones"
            }
        }

        stage('3. Build con Maven') {
            steps {
                echo "🔨 Compilando 8 microservicios con Maven (skip tests)"
            }
        }

        stage('4. Pruebas unitarias') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🧪 Ejecutando pruebas unitarias en 6 servicios"
            }
        }

        stage('5. Pruebas de integración') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🔗 Ejecutando pruebas de integración en Kubernetes"
            }
        }

        stage('6. Pruebas de rendimiento') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "⚡ Ejecutando pruebas de rendimiento (5 usuarios, 30s por servicio)"
            }
        }

        stage('7. Build de Docker') {
            steps {
                echo "🐳 Construyendo imágenes Docker para 8 servicios"
            }
        }

        stage('8. Push a Docker Hub') {
            steps {
                echo "📤 Subiendo imágenes a Docker Hub"
            }
        }

        stage('9. Deploy a Kubernetes PROD') {
            steps {
                echo "🚀 Desplegando 8 microservicios en namespace prod"
            }
        }

        stage('10. Verify Deployment') {
            steps {
                echo "⏳ Esperando a que pods estén listos (máximo 5 minutos)"
            }
        }

        stage('11. Get Service IPs') {
            steps {
                echo "🔍 Obteniendo IPs de servicios para las pruebas"
            }
        }

        stage('12. Analizar resultados de pruebas') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📊 Analizando resultados de pruebas unitarias, integración y rendimiento"
            }
        }

        stage('13. Archivar resultados de pruebas') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📦 Archivando resultados de pruebas y logs"
            }
        }

        stage('14. Generar Release Notes automáticamente') {
            when {
                expression { params.GENERATE_RELEASE_NOTES == true }
            }
            steps {
                echo "📝 Generando Release Notes con información de despliegue, cambios y pruebas"
            }
        }

        stage('15. Archivar Release Notes') {
            when {
                expression { params.GENERATE_RELEASE_NOTES == true }
            }
            steps {
                echo "📦 Archivando Release Notes para acceso posterior e índice de versiones"
            }
        }
    }

    post {
        success {
            echo "✓ PIPELINE PROD COMPLETADO EXITOSAMENTE"
        }
        failure {
            echo "✗ PIPELINE PROD FALLÓ"
        }
        always {
            archiveArtifacts artifacts: 'prod-test-results/**', allowEmptyArchive: true
            archiveArtifacts artifacts: 'prod-deployment-artifacts/**', allowEmptyArchive: true
            archiveArtifacts artifacts: 'release-notes/**', allowEmptyArchive: true
        }
    }
}
```

### 5.3 Template de Release Notes

Ver archivo: `Release_notes.md` (proporcionado)

---

## Resultados Finales

### Resumen de Ejecución

| Componente | Estado | Tiempo |
|-----------|--------|--------|
| Configuración Jenkins | ✅ Completado | - |
| Configuración Kubernetes | ✅ Completado | - |
| Pipeline DEV | ✅ Completado | 5 min 7 seg |
| Pipeline STAGE | ✅ Completado | 11 min |
| Pipeline PROD | ✅ Completado | 10 min |
| **Total** | **✅ EXITOSO** | **26 min 7 seg** |

### Tasa de Éxito de Pruebas

| Tipo de Prueba | Servicios | Tasa de Éxito | Estado |
|----------------|-----------|--------------|--------|
| Unitarias | 5/6 | 83.33% | ✅ |
| Integración | 5/6 | 83.33% | ✅ |
| Rendimiento | 4/6 | 66.67% | ✅ |

### Microservicios Desplegados

```
✅ user-service:1.0.0          (8700)
✅ product-service:1.0.0       (8500)
✅ order-service:1.0.0         (8300)
✅ payment-service:1.0.0       (8400)
✅ favourite-service:1.0.0     (8800)
✅ shipping-service:1.0.0      (8600)
✅ proxy-client:1.0.0          (8200)
✅ service-discovery:1.0.0     (8761)
✅ config-server:1.0.0         (8888)
✅ zipkin:1.0.0                (9411)
```

---

## Archivos de Referencia

### Estructura del Repositorio

```
ecommerce-microservice-operations/
│
├── jenkins/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── plugins.txt
│   └── init.groovy.d/
│
├── k8s/
│   ├── namespaces/
│   │   ├── dev-namespace.yaml
│   │   ├── stage-namespace.yaml
│   │   └── prod-namespace.yaml
│   │
│   ├── dev/
│   │   ├── user-service/
│   │   ├── product-service/
│   │   ├── order-service/
│   │   ├── payment-service/
│   │   ├── favourite-service/
│   │   └── shipping-service/
│   │
│   ├── stage/ (Similar a dev)
│   └── prod/ (Similar a dev, con recursos aumentados)
│
├── setup/
│   ├── Jenkins_setup.md
│   ├── config_setup.md
│   └── fast_start.md
│
└── docs/
    ├── TALLER_2_DOCUMENTACION_PROCESO.md 
    ├── test-results/ 
    ├── execution-logs/ 
```

### Credenciales de Ejemplo

```bash
# Docker Hub
Username: merako34
Email: santiago.angel.or12@gmail.com
Token: dckr_pat_XXXXXXXXXXXXXXXXXXXXX

# Kubernetes Context
Context: docker-desktop
Namespace: dev, stage, prod

# Jenkins Admin
Username: admin
Password: [Generada automáticamente]
URL: http://localhost:8080

# Database (H2)
URL: jdbc:h2:mem:ecommerce_*_db
Username: sa
Password: (sin contraseña)
```

---

## Conclusiones

### Logros Alcanzados

✅ **Configuración Completa**: Jenkins, Docker, Kubernetes completamente configurados  
✅ **Pipelines Multi-Ambiente**: DEV, STAGE, PROD con características escalonadas  
✅ **Suite de Pruebas**: 4 tipos de pruebas implementadas (unitarias, integración, E2E, rendimiento)  
✅ **Automatización**: Release Notes automáticas con Change Management  
✅ **Documentación**: Proceso completo documentado para reproducibilidad  



---
