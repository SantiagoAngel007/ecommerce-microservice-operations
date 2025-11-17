# Terraform - Infrastructure as Code para Ecommerce Microservices

Esta carpeta contiene la configuración completa de infraestructura para el proyecto de microservicios de e-commerce usando **Google Cloud Platform (GCP)** y **Google Kubernetes Engine (GKE)**.

## 📋 Contenido

- [Estructura](#estructura)
- [Requisitos Previos](#requisitos-previos)
- [Configuración Inicial](#configuración-inicial)
- [Despliegue por Ambiente](#despliegue-por-ambiente)
- [Arquitectura](#arquitectura)
- [Comandos Comunes](#comandos-comunes)
- [Backend Remoto](#backend-remoto)
- [Troubleshooting](#troubleshooting)

## 🏗️ Estructura

```
terraform/
├── main.tf                          # Infraestructura principal (VPC, GKE, Cloud SQL, etc)
├── variables.tf                     # Definición de variables
├── outputs.tf                       # Outputs globales
├── providers.tf                     # Configuración de providers (Google, Kubernetes, Helm)
├── .gitignore                       # Archivos a ignorar en Git
│
├── environments/                    # Configuración por ambiente
│   ├── dev/
│   │   ├── terraform.tfvars        # Variables específicas para desarrollo
│   │   ├── backend.tf              # Configuración de backend remoto
│   │   └── main.tf
│   ├── stage/
│   │   ├── terraform.tfvars        # Variables específicas para staging
│   │   ├── backend.tf
│   │   └── main.tf
│   └── prod/
│       ├── terraform.tfvars        # Variables específicas para producción
│       ├── backend.tf
│       └── main.tf
│
├── credentials/                     # (NO en Git) Archivos de credenciales
│   └── gcp-key.json                # Service Account key (NUNCA comitear)
│
├── backend-setup.md                # Guía de configuración de backend remoto
├── README.md                        # Este archivo
└── kubeconfig-template.sh          # Template para configurar kubectl
```

## ✅ Requisitos Previos

### Herramientas Instaladas
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (opcional, para aplicaciones)

### Configuración en GCP
1. ✅ Proyecto GCP creado: `ecommerce-microservices-478116`
2. ✅ Service Account creada: `terraform-sa@ecommerce-microservices-478116.iam.gserviceaccount.com`
3. ✅ Clave JSON descargada y guardada en `credentials/gcp-key.json`
4. ✅ APIs habilitadas en GCP
5. ✅ Bucket de Cloud Storage creado: `ecommerce-terraform-state-ssd`

### Autenticación
```bash
# Configurar gcloud CLI
gcloud auth application-default login

# O usar la clave JSON directamente
export GOOGLE_APPLICATION_CREDENTIALS="./credentials/gcp-key.json"
```

## 🚀 Configuración Inicial

### Paso 1: Clonar el repositorio
```bash
cd ecommerce-microservice-operations
cd terraform
```

### Paso 2: Crear la carpeta de credenciales
```bash
mkdir credentials
# Coloca el archivo gcp-key.json aquí (NO lo comitees)
```

### Paso 3: Inicializar Terraform (ambiente de desarrollo)

**Opción A: Backend Local (para testing)**
```bash
cd environments/dev
terraform init

# Esto inicializa Terraform con estado local
# Útil para testing antes de usar backend remoto
```

**Opción B: Backend Remoto (recomendado)**

Primero edita `environments/dev/backend.tf` y descomentar la configuración de GCS (si está comentada).

```bash
cd environments/dev
terraform init

# Terraform te preguntará si deseas migrar el estado local al backend remoto
# Responde: yes
```

### Paso 4: Validar la configuración
```bash
terraform validate
```

### Paso 5: Ver el plan
```bash
terraform plan -var-file="terraform.tfvars" -out=dev.tfplan
```

## 📦 Despliegue por Ambiente

### Despliegue en Desarrollo

```bash
cd environments/dev

# Inicializar
terraform init

# Validar
terraform validate

# Plan
terraform plan -out=dev.tfplan

# Apply
terraform apply "dev.tfplan"

# Ver outputs
terraform output
```

**Recursos creados en dev:**
- GKE Cluster con 2 nodos (e2-standard-2)
- Cloud SQL PostgreSQL (db-f1-micro)
- VPC y Subnets
- Artifact Registry
- Service Accounts

**Tiempo de despliegue:** ~15-20 minutos

### Despliegue en Staging

```bash
cd environments/stage

terraform init
terraform plan -out=stage.tfplan
terraform apply "stage.tfplan"
```

**Recursos creados en stage:**
- GKE Cluster con 2-5 nodos (e2-standard-4, autoscaling)
- Cloud SQL PostgreSQL con HA (db-custom-2-7680)
- VPC y Subnets separadas

### Despliegue en Producción

```bash
cd environments/prod

terraform init
terraform plan -out=prod.tfplan

# Requiere aprobación manual antes de aplicar
terraform apply "prod.tfplan"
```

**Recursos creados en prod:**
- GKE Cluster con 3-10 nodos (e2-standard-4, autoscaling, HA)
- Cloud SQL PostgreSQL Regional HA (db-custom-4-15360)
- Protección contra eliminación accidental
- Configuración de alta disponibilidad

## 🏛️ Arquitectura

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                      GCP Project                            │
│            ecommerce-microservices-478116                   │
└─────────────────────────────────────────────────────────────┘

├─ VPC Network
│  ├─ Subnet (Primary CIDR: 10.x.0.0/16)
│  ├─ Secondary Range (Pods: 10.4.0.0/14)
│  ├─ Secondary Range (Services: 10.8.0.0/20)
│  └─ Firewall Rules
│
├─ GKE Cluster
│  ├─ Control Plane (Google Managed)
│  ├─ Node Pool (2-10 nodos según ambiente)
│  ├─ Workload Identity (para acceso a GCP APIs)
│  ├─ Network Policy enabled
│  └─ Logging & Monitoring integrated
│
├─ Cloud SQL Database
│  ├─ PostgreSQL 15
│  ├─ Automatic Backups
│  ├─ Private IP (dentro de VPC)
│  └─ Regional HA (en prod)
│
├─ Artifact Registry
│  └─ Docker repository (microservices-dev/stage/prod)
│
└─ Cloud Storage (State)
   └─ Bucket: ecommerce-terraform-state-ssd
      ├─ dev/terraform.tfstate
      ├─ stage/terraform.tfstate
      └─ prod/terraform.tfstate
```

### Networking

```
Internet
    ↓
Cloud Load Balancer (ALB - se configura luego)
    ↓
GKE Ingress Controller (nginx-ingress)
    ↓
API Gateway (puerto 8080)
    ↓
Microservicios en Kubernetes
    ↓
Cloud SQL (Privado dentro de VPC)
```

### Seguridad

- ✅ Workload Identity: Pods acceden a GCP APIs sin credenciales explícitas
- ✅ Network Policies: Restricción de tráfico entre pods
- ✅ Shielded GKE Nodes: Secure boot, integrity monitoring
- ✅ Private Cloud SQL: Acceso solo desde VPC
- ✅ Secret Manager: Gestión centralizada de secretos
- ✅ RBAC: Control de acceso en Kubernetes

## 🔧 Comandos Comunes

### Validación y Planificación

```bash
# Validar sintaxis
terraform validate

# Ver plan (sin aplicar)
terraform plan

# Guardar plan a archivo
terraform plan -out=tfplan

# Ver recursos que serán destruidos
terraform plan -destroy
```

### Aplicación de Cambios

```bash
# Aplicar automáticamente (sin confirmación)
terraform apply -auto-approve

# Aplicar un plan guardado
terraform apply tfplan

# Aplicar solo un recurso específico
terraform apply -target=google_container_cluster.primary
```

### Inspección del Estado

```bash
# Mostrar todos los outputs
terraform output

# Mostrar un output específico
terraform output gke_cluster_name

# Ver el estado completo
terraform show

# Listar recursos en el estado
terraform state list

# Ver detalles de un recurso
terraform state show google_container_cluster.primary
```

### Modificación de Estado

```bash
# Refresco del estado local
terraform refresh

# Remover un recurso del estado (sin destruirlo)
terraform state rm google_container_cluster.primary

# Mover un recurso en el estado
terraform state mv google_container_cluster.primary google_container_cluster.prod_cluster
```

### Limpieza

```bash
# Destruir todos los recursos
terraform destroy

# Destruir sin confirmación
terraform destroy -auto-approve

# Destruir solo un recurso
terraform destroy -target=google_sql_database_instance.instance
```

### Debugging

```bash
# Ver logs detallados
export TF_LOG=DEBUG
terraform apply

# Ver logs de un nivel específico
export TF_LOG=TRACE
terraform plan

# Desactivar logs
unset TF_LOG
```

## 🔐 Backend Remoto

El estado de Terraform se almacena en **Google Cloud Storage** para:

1. **Colaboración:** Múltiples miembros del equipo pueden trabajar
2. **Seguridad:** El estado está encriptado y versionado
3. **Confiabilidad:** Backups automáticos en GCS
4. **Locks:** Previene cambios simultáneos

### Estructura de Estados

```
gs://ecommerce-terraform-state-ssd/
├── dev/terraform.tfstate
├── stage/terraform.tfstate
└── prod/terraform.tfstate
```

### Configurar Backend Remoto

Ver archivo: `backend-setup.md`

### Verificar Estado Remoto

```bash
# Ver contenido del bucket
gsutil ls gs://ecommerce-terraform-state-ssd

# Ver un estado específico
gsutil cat gs://ecommerce-terraform-state-ssd/dev/terraform.tfstate | jq .

# Ver versiones
gsutil versioning get gs://ecommerce-terraform-state-ssd
```

## 🔗 Conexión a GKE

Una vez desplegado, conectar a kubectl:

```bash
# Automático (se genera automáticamente)
bash kubeconfig-dev.sh

# O manual
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --region southamerica-east1 \
  --project ecommerce-microservices-478116

# Verificar conexión
kubectl get nodes
kubectl get namespaces
```

## 📊 Costos Estimados (Free Trial)

Para el Free Trial ($300 USD, 90 días):

| Componente | Costo (primeros meses) |
|-----------|------------------------|
| GKE (dev: 2 nodos, stage: 2-5, prod: 3-10) | ~$200-300/mes |
| Cloud SQL (3 instancias) | ~$50-100/mes |
| Storage (state, logs, etc) | ~$5-10/mes |
| **TOTAL ESTIMADO** | **$255-410/mes** |

⚠️ **Nota:** El Free Trial termina en 90 días. Monitorea costos en la consola de GCP.

## 🐛 Troubleshooting

### Error: "Failed to get credentials"

```bash
# Verifica la ruta del archivo de credenciales
export GOOGLE_APPLICATION_CREDENTIALS="./credentials/gcp-key.json"

# O autentica con gcloud
gcloud auth application-default login
```

### Error: "Quota exceeded"

Algunos servicios pueden tener quotas limitadas:
- Solicitar aumento de cuota en GCP Console
- O usar tipos de máquinas más pequeños

### Error: "Cluster creation failed"

Si el cluster tarda más de 20 minutos:
```bash
# Espera un poco más (a veces tarda 30 min)
# O consulta los logs en GCP Console > GKE > Eventos
```

### Error: "Backend migration failed"

Si hay problemas al migrar al backend remoto:
```bash
# Fuerza la inicialización sin migración
terraform init -reconfigure

# Luego migra manualmente
terraform init -migrate-state
```

### Base de datos no accesible desde pods

Verifica:
1. La conexión privada VPC está establecida
2. Workload Identity está configurado
3. IAM binding para Cloud SQL Client existe

```bash
# Ver logs de pod
kubectl logs <pod-name>

# Probar conectividad
kubectl run -it --image=postgresql:15 psql -- \
  psql -h <PRIVATE_IP> -U dbuser ecommerce_db
```

## 📚 Referencias

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud SQL Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

## 👥 Soporte

Para problemas con Terraform:
- Revisa los logs: `terraform apply -v`
- Consulta la documentación oficial
- Abre un issue en el repositorio

---

**Última actualización:** Noviembre 2024
**Versión de Terraform recomendada:** >= 1.0
**Versión de GCP Provider:** ~> 5.0
