# Guía: Configuración de GCP para el Equipo

## 🎯 Objetivos

Cada miembro del equipo debe tener acceso a GCP para trabajar con la infraestructura en Google Cloud. Esta guía explica cómo configurar tu ambiente.

## 📋 Prerequisitos

- Cuenta de Google
- `gcloud` CLI instalado (ver sección de instalación)
- Acceso al proyecto GCP: **ecommerce-microservices-478116**

## 1️⃣ Instalación de Google Cloud SDK

### En Windows
```bash
# Descargar instalador
https://cloud.google.com/sdk/docs/install-cloud-sdk

# O con Chocolatey (si está instalado)
choco install google-cloud-sdk

# Verificar instalación
gcloud --version
```

### En Mac/Linux
```bash
# Descargar y instalar
curl https://sdk.cloud.google.com | bash

# Reiniciar terminal y verificar
gcloud --version
```

## 2️⃣ Autenticación en GCP

```bash
# Iniciar sesión con tu cuenta de Google
gcloud auth login

# Establecer proyecto por defecto
gcloud config set project ecommerce-microservices-478116

# Verificar
gcloud config list
```

## 3️⃣ Crear Service Account y Descargar Credenciales

Cada desarrollador debe crear su propia clave de Service Account para Terraform.

### A través de GCP Console

```
1. Ir a: IAM & Admin → Service Accounts
2. Seleccionar "terraform-dev" (o crear si no existe)
3. Ir a "Keys"
4. Crear nueva clave → JSON
5. Se descargará un archivo: `<nombre>-<hash>.json`
6. Renombrarlo a `gcp-key.json`
7. Copiarlo a: terraform/credentials/gcp-key.json
```

### Permisos Necesarios para la Service Account

La Service Account debe tener estos roles:
- **Editor** (para DEV) o permisos específicos (STAGE/PROD)
- Kubernetes Engine Admin
- Compute Admin
- Cloud SQL Admin
- Service Networking Admin

## 4️⃣ Verificar Acceso a Recursos GCP

```bash
# Verificar acceso a GKE
gcloud container clusters list --project=ecommerce-microservices-478116

# Debería mostrar:
# ecommerce-dev-cluster
# ecommerce-stage-cluster
# ecommerce-prod-cluster

# Configurar kubectl para conectarse a un cluster
gcloud container clusters get-credentials ecommerce-dev-cluster --zone us-central1-a

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

## 5️⃣ Verificar Acceso al Backend de Terraform (GCS)

```bash
# Listar buckets GCS
gsutil ls

# Ver contenido del bucket de estado
gsutil ls gs://ecommerce-terraform-state-ssd/

# Ver estado actual
gsutil cat gs://ecommerce-terraform-state-ssd/dev/terraform.tfstate
```

## 6️⃣ Verificar APIs Habilitadas

```bash
# Listar APIs habilitadas en el proyecto
gcloud services list --enabled

# Habilitar una API específica (si falta)
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

## 7️⃣ Configuración de `env.config`

Crear/completar `env.config` en la raíz del repo:

```bash
# env.config
export GCP_PROJECT_ID="ecommerce-microservices-478116"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

# Kubernetes contexts
export DEV_CLUSTER="ecommerce-dev-cluster"
export STAGE_CLUSTER="ecommerce-stage-cluster"
export PROD_CLUSTER="ecommerce-prod-cluster"

# Artifact Registry
export DEV_REGISTRY="us-central1-docker.pkg.dev/ecommerce-microservices-478116/microservices-dev"
export STAGE_REGISTRY="us-central1-docker.pkg.dev/ecommerce-microservices-478116/microservices-stage"
export PROD_REGISTRY="us-central1-docker.pkg.dev/ecommerce-microservices-478116/microservices-prod"
```

Cargar las variables:
```bash
source env.config
```

## 📊 Estructura de Ambientes en GCP

| Recurso | DEV | STAGE | PROD |
|---------|-----|-------|------|
| GKE Cluster | `ecommerce-dev-cluster` | `ecommerce-stage-cluster` | `ecommerce-prod-cluster` |
| VPC | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Cloud SQL | ecommerce-dev-db | ecommerce-stage-db | ecommerce-prod-db |
| Artifact Registry | microservices-dev | microservices-stage | microservices-prod |

## ✅ Checklist Final

- [ ] `gcloud` CLI instalado
- [ ] Sesión iniciada (`gcloud auth login`)
- [ ] Proyecto establecido (ecommerce-microservices-478116)
- [ ] `gcp-key.json` descargado en `terraform/credentials/`
- [ ] Acceso a GKE clusters verificado
- [ ] Acceso a GCS buckets verificado
- [ ] `env.config` creado y sourced
- [ ] `kubectl` configurado para al menos DEV cluster

## ⚠️ Notas Importantes

- **NO compartir** el archivo `gcp-key.json` en Slack o correo
- Cada desarrollador usa su propia clave de Service Account
- Los buckets de estado (GCS) son compartidos por el equipo
- Si hay conflictos de estado, comunicarse al equipo antes de hacer cambios

