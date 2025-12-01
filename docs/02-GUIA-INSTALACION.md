# 🛠️ Guía de Instalación Completa

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Tiempo estimado:** 2-3 horas (primera vez)

---

## 📋 Tabla de Contenidos

1. [Pre-requisitos](#pre-requisitos)
2. [Configuración de GCP](#configuración-de-gcp)
3. [Instalación de Herramientas](#instalación-de-herramientas)
4. [Configuración de Credenciales](#configuración-de-credenciales)
5. [Deployment de Infraestructura](#deployment-de-infraestructura)
6. [Deployment de Aplicaciones](#deployment-de-aplicaciones)
7. [Configuración de CI/CD](#configuración-de-cicd)
8. [Verificación del Sistema](#verificación-del-sistema)
9. [Troubleshooting](#troubleshooting)

---

## ✅ Pre-requisitos

### Hardware Mínimo

- **RAM:** 8 GB mínimo (16 GB recomendado)
- **Disco:** 50 GB de espacio libre
- **Procesador:** 4 cores (para compilar localmente)
- **Internet:** Conexión estable (para descarga de imágenes Docker)

### Cuentas Necesarias

- ✅ **Google Cloud Platform**
  - Cuenta con Free Trial activo ($300 créditos) o proyecto existente
  - Permisos de Project Owner o Editor
  - Billing habilitado
  
- ✅ **GitHub**
  - Cuenta con acceso a los repositorios
  - Personal Access Token (para webhooks)

- ✅ **Docker Hub** (opcional)
  - Solo si vas a usar Docker Hub en lugar de Artifact Registry

### Sistema Operativo

Esta guía cubre:
- ✅ **Linux** (Ubuntu 22.04, Fedora 39)
- ✅ **macOS** (Ventura 13+)
- ✅ **Windows** (10/11 con WSL2)

---

## ☁️ Configuración de GCP

### Paso 1: Crear o Seleccionar Proyecto

**📸 Screenshot 13:**
```bash
# Listar proyectos existentes
gcloud projects list

# Crear nuevo proyecto (si es necesario)
gcloud projects create ecommerce-microservices-$(date +%s) \
  --name="E-Commerce Microservices"

# Establecer proyecto por defecto
gcloud config set project YOUR_PROJECT_ID

# Verificar
gcloud config get-value project
```
> **Archivo:** `screenshots/13-gcp-project-setup.png`  
> **Descripción:** Proyecto GCP seleccionado y configurado

### Paso 2: Habilitar APIs Necesarias

**📸 Screenshot 14:**
```bash
# Habilitar todas las APIs necesarias en un solo comando
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com \
  iam.googleapis.com \
  cloudapis.googleapis.com \
  cloudbuild.googleapis.com \
  storage-api.googleapis.com

# Verificar APIs habilitadas
gcloud services list --enabled
```
> **Archivo:** `screenshots/14-gcp-apis-enabled.png`

### Paso 3: Configurar Billing

```bash
# Listar billing accounts
gcloud billing accounts list

# Asociar billing al proyecto
gcloud billing projects link YOUR_PROJECT_ID \
  --billing-account=BILLING_ACCOUNT_ID

# Verificar
gcloud billing projects describe YOUR_PROJECT_ID
```

**⚠️ IMPORTANTE:** Configura alertas de presupuesto para evitar sorpresas:

```bash
# Acceder a GCP Console
# Navigation menu → Billing → Budgets & alerts
# Create Budget:
#   - Name: "E-Commerce Monthly Budget"
#   - Budget amount: $100
#   - Alert thresholds: 50%, 90%, 100%
#   - Email notifications: tu-email@example.com
```

**📸 Screenshot 15:**
> **Archivo:** `screenshots/15-gcp-budget-alerts.png`  
> **Descripción:** Alertas de presupuesto configuradas

### Paso 4: Crear Service Account

**📸 Screenshot 16:**
```bash
# Crear Service Account
gcloud iam service-accounts create ecommerce-terraform \
  --display-name="Terraform Service Account" \
  --description="Service account para Terraform y CI/CD"

# Asignar roles necesarios
PROJECT_ID=$(gcloud config get-value project)
SA_EMAIL="ecommerce-terraform@${PROJECT_ID}.iam.gserviceaccount.com"

# Roles necesarios
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Crear y descargar key
gcloud iam service-accounts keys create ~/gcp-key-terraform.json \
  --iam-account=$SA_EMAIL

# Verificar
gcloud iam service-accounts describe $SA_EMAIL
```
> **Archivo:** `screenshots/16-service-account-created.png`

**⚠️ SEGURIDAD:** Este archivo JSON es crítico. Protégelo:
```bash
# Mover a ubicación segura
mkdir -p ~/.gcp
mv ~/gcp-key-terraform.json ~/.gcp/
chmod 600 ~/.gcp/gcp-key-terraform.json

# NO subir a Git (verificar .gitignore)
echo "*.json" >> .gitignore
echo ".gcp/" >> .gitignore
```

---

## 🔧 Instalación de Herramientas

### 1. Google Cloud SDK (gcloud)

#### Linux (Ubuntu/Debian)
```bash
# Agregar repositorio
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Importar key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Instalar
sudo apt-get update
sudo apt-get install google-cloud-sdk

# Verificar
gcloud version
```

#### Fedora
```bash
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo dnf install google-cloud-sdk
```

#### macOS
```bash
# Con Homebrew
brew install --cask google-cloud-sdk

# Agregar al PATH
echo 'source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"' >> ~/.zshrc
source ~/.zshrc
```

**Inicializar gcloud:**
```bash
# Login
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID

# Configurar región por defecto
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

**📸 Screenshot 17:**
```bash
gcloud version
gcloud config list
```
> **Archivo:** `screenshots/17-gcloud-installed.png`

### 2. kubectl

#### Linux
```bash
# Descargar versión estable
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalar
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar
kubectl version --client
```

#### macOS
```bash
brew install kubectl
```

#### Windows (WSL2)
```bash
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Configurar autocompletado:**
```bash
# Bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# Zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc

# Fish
kubectl completion fish | source
```

**📸 Screenshot 18:**
```bash
kubectl version --client
kubectl cluster-info
```
> **Archivo:** `screenshots/18-kubectl-installed.png`

### 3. Terraform

#### Linux
```bash
# Agregar repositorio HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform

# Verificar
terraform version
```

#### macOS
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

#### Fedora
```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf install terraform
```

**📸 Screenshot 19:**
```bash
terraform version
terraform --help
```
> **Archivo:** `screenshots/19-terraform-installed.png`

### 4. Docker

#### Linux (Ubuntu/Debian)
```bash
# Remover versiones antiguas
sudo apt-get remove docker docker-engine docker.io containerd runc

# Instalar dependencias
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Agregar Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker version
docker run hello-world
```

#### Fedora
```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### macOS
```bash
# Descargar Docker Desktop desde:
# https://www.docker.com/products/docker-desktop/

# O con Homebrew
brew install --cask docker
```

**📸 Screenshot 20:**
```bash
docker version
docker-compose version
docker ps
```
> **Archivo:** `screenshots/20-docker-installed.png`

### 5. Git

```bash
# Linux
sudo apt install git  # Ubuntu/Debian
sudo dnf install git  # Fedora

# macOS (viene preinstalado, o con Homebrew)
brew install git

# Configurar
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@example.com"

# Verificar
git --version
git config --list
```

### 6. Herramientas Adicionales (Opcionales)

```bash
# jq - JSON processor (útil para scripts)
sudo apt install jq  # Linux
brew install jq      # macOS

# yq - YAML processor
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# k9s - Terminal UI para Kubernetes
brew install derailed/k9s/k9s  # macOS/Linux

# kubectx/kubens - Switch contexts/namespaces
brew install kubectx  # macOS
sudo apt install kubectx  # Linux

# Verificar
jq --version
yq --version
k9s version
kubectx
```

---

## 🔐 Configuración de Credenciales

### 1. Configurar gcloud con Service Account

```bash
# Activar Service Account
gcloud auth activate-service-account \
  --key-file=~/.gcp/gcp-key-terraform.json

# Configurar como credencial por defecto para Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# Verificar
gcloud auth list
```

**📸 Screenshot 21:**
```bash
gcloud auth list
gcloud config get-value account
```
> **Archivo:** `screenshots/21-gcloud-auth-configured.png`

### 2. Configurar kubectl con GKE

**Nota:** Este paso se ejecuta DESPUÉS de crear el cluster con Terraform.

```bash
# Obtener credenciales del cluster DEV
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID

# Verificar contexto
kubectl config current-context
kubectl cluster-info

# Ver nodos
kubectl get nodes
```

### 3. Variables de Entorno

Crear archivo de variables de entorno (NO subir a Git):

```bash
# Crear archivo
cat > ~/.env.ecommerce << 'EOF'
# GCP Configuration
export GCP_PROJECT_ID="your-project-id-here"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/gcp-key-terraform.json"

# Terraform
export TF_VAR_project_id="$GCP_PROJECT_ID"
export TF_VAR_region="$GCP_REGION"

# Docker
export DOCKER_REGISTRY="us-central1-docker.pkg.dev/$GCP_PROJECT_ID/ecommerce-services"

# Jenkins
export JENKINS_URL="http://34.123.43.189:8080"
export JENKINS_USER="admin"
export JENKINS_TOKEN="your-token-here"
EOF

# Agregar al shell profile
echo 'source ~/.env.ecommerce' >> ~/.bashrc  # o ~/.zshrc
source ~/.env.ecommerce

# Verificar
echo $GCP_PROJECT_ID
```

---

## 🏗️ Deployment de Infraestructura

### Paso 1: Clonar Repositorios

```bash
# Crear directorio de trabajo
mkdir -p ~/workspace/ecommerce
cd ~/workspace/ecommerce

# Clonar repos
git clone https://github.com/SantiagoAngel007/ecommerce-microservice-operations.git
git clone https://github.com/SantiagoAngel007/ecommerce-microservice-backend-app.git

cd ecommerce-microservice-operations
```

### Paso 2: Configurar Terraform Backend

```bash
# Crear bucket para Terraform state
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="${PROJECT_ID}-terraform-state"

gsutil mb -p $PROJECT_ID -l us-central1 gs://$BUCKET_NAME/

# Habilitar versionado
gsutil versioning set on gs://$BUCKET_NAME/

# Verificar
gsutil ls
```

**📸 Screenshot 22:**
```bash
gsutil ls
gsutil versioning get gs://$BUCKET_NAME/
```
> **Archivo:** `screenshots/22-terraform-backend-bucket.png`

### Paso 3: Configurar Variables de Terraform

```bash
cd terraform/environments/dev

# Crear archivo terraform.tfvars
cat > terraform.tfvars << EOF
project_id = "$GCP_PROJECT_ID"
region     = "us-central1"
zone       = "us-central1-a"

cluster_name = "ecommerce-dev-cluster"
namespace    = "dev"

artifact_registry_name = "ecommerce-services"
artifact_registry_location = "us-central1"

service_account_name = "ecommerce-dev-k8s-workload"

# Networking
vpc_name = "ecommerce-vpc"
subnet_name = "dev-subnet"
subnet_cidr = "10.0.1.0/24"
EOF
```

### Paso 4: Inicializar Terraform

**📸 Screenshot 23:**
```bash
# Inicializar
terraform init

# Ver providers y módulos descargados
ls -la .terraform/

# Validar configuración
terraform validate

# Ver plan (sin ejecutar)
terraform plan -out=tfplan
```
> **Archivo:** `screenshots/23-terraform-init.png`

### Paso 5: Crear Infraestructura DEV

**⚠️ IMPORTANTE:** Este paso consume créditos GCP (~$60/mes para DEV).

**📸 Screenshot 24:**
```bash
# Revisar plan detallado
terraform plan

# Aplicar (requiere confirmación)
terraform apply

# O aplicar sin confirmación (usar con precaución)
terraform apply -auto-approve

# Esperar 10-15 minutos...
# El output mostrará:
#   - Cluster endpoint
#   - Service account email
#   - Artifact Registry URL
```
> **Archivo:** `screenshots/24-terraform-apply-output.png`

**Verificar recursos creados:**
```bash
# Cluster
gcloud container clusters list

# Artifact Registry
gcloud artifacts repositories list

# VPC y Subnets
gcloud compute networks list
gcloud compute networks subnets list --network=ecommerce-vpc

# Service Accounts
gcloud iam service-accounts list
```

**📸 Screenshot 25:**
```bash
gcloud container clusters describe ecommerce-dev-cluster \
  --region=us-central1 \
  --format=yaml | head -50
```
> **Archivo:** `screenshots/25-gke-cluster-created.png`

### Paso 6: Configurar kubectl

```bash
# Obtener credenciales
gcloud container clusters get-credentials ecommerce-dev-cluster \
  --region=us-central1

# Crear namespace
kubectl create namespace dev

# Verificar
kubectl get namespaces
kubectl config set-context --current --namespace=dev
kubectl get all -n dev
```

---

## 🚀 Deployment de Aplicaciones

### Paso 1: Crear ConfigMaps

```bash
cd ../../../k8s/dev

# Revisar ConfigMaps existentes
ls -la */configmap.yaml

# Aplicar ConfigMaps
kubectl apply -f service-discovery/configmap.yaml
kubectl apply -f config-server/configmap.yaml
kubectl apply -f api-gateway/configmap.yaml
kubectl apply -f user-service/configmap.yaml
kubectl apply -f product-service/configmap.yaml
kubectl apply -f order-service/configmap.yaml
kubectl apply -f payment-service/configmap.yaml
kubectl apply -f shipping-service/configmap.yaml
kubectl apply -f favourite-service/configmap.yaml

# Verificar
kubectl get configmaps -n dev
```

**📸 Screenshot 26:**
```bash
kubectl get configmaps -n dev
kubectl describe configmap service-discovery-config -n dev
```
> **Archivo:** `screenshots/26-configmaps-created.png`

### Paso 2: Desplegar Servicios de Infraestructura

**Orden de despliegue (importante):**
1. Service Discovery (Eureka)
2. Config Server
3. API Gateway
4. Zipkin
5. Servicios de negocio

```bash
# 1. Service Discovery
kubectl apply -f service-discovery/

# Esperar a que esté Ready
kubectl wait --for=condition=Ready pod -l app=service-discovery -n dev --timeout=300s

# 2. Config Server
kubectl apply -f config-server/

kubectl wait --for=condition=Ready pod -l app=config-server -n dev --timeout=300s

# 3. API Gateway
kubectl apply -f api-gateway/

# 4. Zipkin
kubectl apply -f zipkin/

# Verificar
kubectl get pods -n dev --watch
```

**📸 Screenshot 27:**
```bash
kubectl get pods -n dev
kubectl get svc -n dev
```
> **Archivo:** `screenshots/27-infrastructure-services-running.png`

### Paso 3: Desplegar Servicios de Negocio

```bash
# Desplegar todos los servicios de negocio
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f shipping-service/
kubectl apply -f favourite-service/

# Monitorear deployment
kubectl get pods -n dev --watch

# Esperar a que todos estén Running
kubectl wait --for=condition=Ready pod --all -n dev --timeout=600s
```

**📸 Screenshot 28:**
```bash
kubectl get pods -n dev -o wide
kubectl get svc -n dev
kubectl top pods -n dev
```
> **Archivo:** `screenshots/28-all-services-running.png`

---

## 🔄 Configuración de CI/CD

### Paso 1: Acceder a Jenkins

```bash
# Obtener IP de Jenkins (si usaste Terraform para crearlo)
gcloud compute instances describe jenkins-server \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Abrir navegador
# http://<JENKINS-IP>:8080
```

**Si Jenkins no existe, créalo:**
```bash
cd setup
./jenkins-setup.sh
```

**📸 Screenshot 29:**
> **Archivo:** `screenshots/29-jenkins-dashboard.png`  
> **Descripción:** Dashboard de Jenkins con jobs configurados

### Paso 2: Configurar Credenciales en Jenkins

1. **Dashboard → Manage Jenkins → Manage Credentials**

2. **Agregar GCP Service Account:**
   - Kind: Secret file
   - File: `gcp-key-terraform.json`
   - ID: `gcp-service-account-key`
   - Description: GCP Service Account

3. **Agregar GitHub Token:**
   - Kind: Username with password
   - Username: `tu-usuario-github`
   - Password: `ghp_xxxxxxxxxxxxx`
   - ID: `github-credentials`
   - Description: GitHub Personal Access Token

**📸 Screenshot 30:**
> **Archivo:** `screenshots/30-jenkins-credentials.png`

### Paso 3: Crear Pipelines

```bash
# Pipeline DEV
# Jenkins → New Item → ecommerce-dev-pipeline
# Type: Pipeline
# Pipeline script from SCM:
#   SCM: Git
#   Repository URL: https://github.com/SantiagoAngel007/ecommerce-microservice-operations
#   Script Path: pipelines/Jenkinsfile.dev-gcp

# Pipeline STAGE
# Similar pero con Jenkinsfile.stage-gcp
```

### Paso 4: Configurar Webhooks GitHub

```bash
# En GitHub:
# Repository → Settings → Webhooks → Add webhook

# Payload URL:
http://<JENKINS-IP>:8080/generic-webhook-trigger/invoke?token=dev-webhook-token-2024

# Content type: application/json
# Events: Just the push event
# Active: ✅
```

**📸 Screenshot 31:**
> **Archivo:** `screenshots/31-github-webhooks.png`

---

## ✅ Verificación del Sistema

### Checklist Completo

```bash
# 1. ✅ GCP Resources
gcloud container clusters list
gcloud artifacts repositories list
gcloud compute instances list

# 2. ✅ Kubernetes Cluster
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# 3. ✅ Pods Running
kubectl get pods -n dev
# Todos deben estar Running (1/1)

# 4. ✅ Services Accessible
kubectl get svc -n dev
# Obtener EXTERNAL-IPs

# 5. ✅ Health Checks
curl http://<SERVICE-DISCOVERY-IP>:8761/actuator/health
curl http://<API-GATEWAY-IP>:8200/actuator/health

# 6. ✅ Service Discovery
# Abrir navegador: http://<SERVICE-DISCOVERY-IP>:8761
# Ver todos los servicios registrados

# 7. ✅ Distributed Tracing
# Abrir navegador: http://<ZIPKIN-IP>:9411
# Hacer request y ver trace

# 8. ✅ End-to-End Test
curl http://<API-GATEWAY-IP>:8200/api/user-service/users
curl http://<API-GATEWAY-IP>:8200/api/product-service/products
curl http://<API-GATEWAY-IP>:8200/api/order-service/orders

# 9. ✅ Jenkins
# Abrir: http://<JENKINS-IP>:8080
# Ejecutar build manual

# 10. ✅ CI/CD Webhook
# Hacer push a rama dev
# Verificar que pipeline se ejecuta automáticamente
```

**📸 Screenshot 32:**
```bash
# Captura con todos los checks
kubectl get all -n dev
curl http://<API-GATEWAY-IP>:8200/actuator/health | jq
```
> **Archivo:** `screenshots/32-system-verification-complete.png`

---

## 🔧 Troubleshooting

### Problema 1: Pods en estado Pending

**Síntomas:**
```bash
kubectl get pods -n dev
# NAME                      READY   STATUS    RESTARTS   AGE
# product-service-xxx       0/1     Pending   0          5m
```

**Causas posibles:**
- No hay nodos disponibles en el cluster
- Recursos insuficientes (CPU/RAM)
- PersistentVolumeClaim no bound

**Solución:**
```bash
# Ver eventos
kubectl describe pod <pod-name> -n dev

# Ver nodos y recursos
kubectl get nodes
kubectl top nodes

# Si es GKE Autopilot, esperar auto-scaling (5-10 min)
# O escalar manualmente en GKE Standard:
gcloud container clusters resize ecommerce-dev-cluster \
  --num-nodes=3 \
  --zone=us-central1-a
```

### Problema 2: ImagePullBackOff

**Síntomas:**
```bash
kubectl get pods -n dev
# NAME                      READY   STATUS             RESTARTS   AGE
# user-service-xxx          0/1     ImagePullBackOff   0          2m
```

**Solución:**
```bash
# Ver detalles del error
kubectl describe pod <pod-name> -n dev

# Verificar que la imagen existe
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-services

# Verificar permisos de Artifact Registry
kubectl get serviceaccount default -n dev -o yaml

# Re-configurar Docker credentials
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Problema 3: CrashLoopBackOff

**Síntomas:**
```bash
# Pod reiniciando constantemente
kubectl get pods -n dev
# NAME                      READY   STATUS             RESTARTS   AGE
# order-service-xxx         0/1     CrashLoopBackOff   5          10m
```

**Solución:**
```bash
# Ver logs del pod
kubectl logs <pod-name> -n dev --previous

# Revisar health checks
kubectl describe pod <pod-name> -n dev

# Verificar variables de entorno
kubectl exec -it <pod-name> -n dev -- env

# Verificar ConfigMap
kubectl get configmap order-service-config -n dev -o yaml
```

### Problema 4: Service Discovery no registra servicios

**Síntomas:**
- Eureka dashboard vacío
- Servicios no se encuentran entre sí

**Solución:**
```bash
# Verificar conectividad a Eureka
kubectl exec -it <service-pod> -n dev -- \
  curl http://service-discovery:8761/eureka/apps

# Revisar ConfigMap
kubectl get configmap <service>-config -n dev -o yaml

# Verificar variable EUREKA_CLIENT_SERVICE_URL
# Debe ser: http://service-discovery:8761/eureka
```

### Problema 5: Terraform apply falla

**Error común:**
```
Error: Error creating Cluster: googleapi: Error 403: 
Required "container.clusters.create" permission(s) for "projects/..."
```

**Solución:**
```bash
# Verificar Service Account tiene permisos
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:ecommerce-terraform@*"

# Agregar rol faltante
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:ecommerce-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"
```

### Problema 6: Jenkins pipeline falla en deploy

**Error:** `Error from server (Forbidden): error when retrieving current configuration`

**Solución:**
```bash
# Verificar kubeconfig en Jenkins
# Jenkins → job → Configure → Build Environment
# Agregar binding para KUBECONFIG

# O configurar Service Account para Jenkins
kubectl create serviceaccount jenkins -n dev
kubectl create clusterrolebinding jenkins-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=dev:jenkins
```

---

## 📞 Soporte

Si encuentras problemas no cubiertos en esta guía:

1. **Revisar logs:**
   ```bash
   kubectl logs -n dev <pod-name>
   kubectl describe pod -n dev <pod-name>
   ```

2. **Revisar documentación oficial:**
   - [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
   - [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
   - [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)

3. **Contactar al equipo:**
   - Email: dsmalte2002@gmail.com
   - GitHub Issues: [Reportar problema](https://github.com/SantiagoAngel007/ecommerce-microservice-operations/issues)

---

## 📚 Próximos Pasos

Una vez completada la instalación:

1. ✅ **[Manual de Operaciones](03-MANUAL-OPERACIONES.md)** - Operaciones diarias
2. ✅ **[Análisis de Costos](04-COSTOS-INFRAESTRUCTURA.md)** - Monitoreo de gastos
3. ✅ **[Guía de Screenshots](05-GUIA-SCREENSHOTS.md)** - Evidencias visuales
4. ✅ **[Video Demo](06-VIDEO-DEMO.md)** - Grabación de demostración

---

**✅ ¡Instalación completada! Tu sistema está listo para producción.**
