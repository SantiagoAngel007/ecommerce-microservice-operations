# 🔧 Configuración de Jenkins para GCP

Este documento describe cómo configurar Jenkins para ejecutar el Jenkinsfile.infrastructure con seguridad en GCP.

---

## 📋 Requisitos Previos

✅ Jenkins 2.479.1+ LTS
✅ Docker instalado y running
✅ GCP Project (ecommerce-microservices-478116)
✅ Service Account en GCP con permisos

---

## 🔐 PASO 1: Crear Service Account en GCP

### **1.1 Crear Service Account:**

```bash
# Usando gcloud CLI
gcloud iam service-accounts create terraform-jenkins \
    --display-name="Terraform Jenkins Pipeline" \
    --project=ecommerce-microservices-478116
```

### **1.2 Asignar roles necesarios:**

```bash
# Permisos de Compute (GKE)
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/container.admin

# Permisos de Networking (VPC, Firewall)
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/compute.networkAdmin

# Permisos de Cloud SQL
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/cloudsql.admin

# Permisos de Storage (para backend remoto)
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/storage.admin

# Permisos de Artifact Registry
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/artifactregistry.admin

# Permisos de Secret Manager
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/secretmanager.admin

# Permisos para habilitar APIs
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/serviceusage.serviceUsageAdmin
```

### **1.3 Crear y descargar key JSON:**

```bash
# Crear key
gcloud iam service-accounts keys create ./gcp-key.json \
    --iam-account=terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --project=ecommerce-microservices-478116

# Verificar que se creó
ls -la gcp-key.json
```

**⚠️ IMPORTANTE:** Guardar este archivo en lugar seguro. **NUNCA commitear a Git.**

---

## 🔑 PASO 2: Configurar Credenciales en Jenkins

### **2.1 Acceder a Jenkins:**

```
http://localhost:8080
```

Usar credenciales configuradas en `jenkins/init.groovy.d/basic-security.groovy`:
- Usuario: `admin`
- Contraseña: `admin123`

### **2.2 Agregar GCP Service Account Key:**

1. **Navigate to:**
   - Jenkins → Manage Jenkins → Credentials

2. **Click en "System"**

3. **Click en "Global credentials (unrestricted)"**

4. **Click "Add Credentials"**

5. **Llenar formulario:**
   ```
   Kind:              Secret file
   File:              Seleccionar gcp-key.json
   ID:                gcp-service-account-key
   Description:       GCP Service Account para Terraform
   Scope:             Global
   ```

6. **Click "Create"**

### **2.3 Verificar que se agregó:**

```bash
# Debería aparecer:
Credentials
├── System
│   └── Global credentials (unrestricted)
│       └── gcp-service-account-key (GCP Service Account)
```

---

## 📦 PASO 3: Instalar Plugins Necesarios

Jenkins ya tiene la mayoría, pero verificar en **Manage Jenkins → Plugins → Installed**:

**Plugins necesarios:**
- ✅ git
- ✅ docker-workflow
- ✅ kubernetes
- ✅ kubernetes-cli
- ✅ maven-plugin
- ✅ pipeline-aggregator
- ✅ credentials
- ✅ junit

**Plugins recomendados (agregar si no están):**
- `timestamper` - Agregar timestamps a logs
- `AnsiColor` - Colores en logs
- `Email Extension` - Notificaciones

**Para agregar plugins:**

1. Manage Jenkins → Plugins → Available plugins
2. Buscar plugin
3. Marcar checkbox
4. Click "Install now"

---

## 🔧 PASO 4: Crear Job en Jenkins

### **4.1 Crear nuevo pipeline job:**

1. **Jenkins Dashboard**
2. **"New Item"**
3. **Nombre:** `ecommerce-microservice-infrastructure`
4. **Tipo:** Pipeline
5. **Click "OK"**

### **4.2 Configurar pipeline:**

**General:**
```
Description: Gestiona infraestructura en GCP usando Terraform
Discard old builds: 30 days
Concurrent builds: No (deshabilitado)
```

**Build Triggers:**
```
Poll SCM: No
Webhook: No
⚠️ IMPORTANTE: NO automático, solo manual
```

**Pipeline:**
```
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/SelimHorri/ecommerce-microservice-operations.git
Branch: */main
Script Path: pipelines/Jenkinsfile.infrastructure
```

### **4.3 Click "Save"**

---

## ✅ PASO 5: Configurar Grupos de Usuarios (RBAC)

Para que solo ciertos usuarios puedan ejecutar en producción:

### **5.1 Crear grupo devops-team:**

En `jenkins/init.groovy.d/basic-security.groovy`, agregar:

```groovy
// Crear usuario adicional para devops
def hudsonRealm = Jenkins.getInstance().getSecurityRealm()
if (hudsonRealm instanceof HudsonPrivateSecurityRealm) {
    if (hudsonRealm.getUser("devops1") == null) {
        hudsonRealm.createAccount("devops1", "secure_password_here")
    }
    if (hudsonRealm.getUser("devops2") == null) {
        hudsonRealm.createAccount("devops2", "secure_password_here")
    }
}
```

### **5.2 O usar LDAP/OAuth para gestionar grupos:**

Consultar documentación de Jenkins para integración con:
- GitHub OAuth
- LDAP / Active Directory
- Google Cloud Identity

---

## 🧪 PASO 6: Probar la Configuración

### **Test 1: Verificar credenciales**

```bash
# En Jenkins terminal o pipeline:
sh '''
    gcloud auth activate-service-account --key-file=${GCP_CREDENTIALS_FILE}
    gcloud config set project ecommerce-microservices-478116
    gcloud auth list
    gcloud projects get-iam-policy ecommerce-microservices-478116 \
        --flatten="bindings[].members" \
        --filter="bindings.members:terraform-jenkins*"
'''
```

### **Test 2: Ejecutar pipeline con PLAN**

1. En Jenkins: ecommerce-microservice-infrastructure
2. "Build with Parameters"
3. Configurar:
   ```
   ENVIRONMENT: dev
   ACTION:      plan
   AUTO_APPROVE: false
   ```
4. Click "Build"
5. Verificar en logs:
   ```
   ✅ Terraform plan completado exitosamente
   ```

### **Test 3: Verificar outputs se guardaron**

Después de la ejecución:
1. Build → Artifacts
2. Debería haber:
   - terraform-outputs.json
   - terraform.env
   - terraform.log

---

## 📊 Variables de Entorno Global

Configurar variables globales en Jenkins:

**Manage Jenkins → System Configuration → Global properties:**

```
GCP_PROJECT_ID=ecommerce-microservices-478116
GCP_REGION=southamerica-east1
TERRAFORM_VERSION=1.5.0
```

---

## 🔐 Seguridad: Checklist

- [ ] Service Account creada en GCP
- [ ] Key JSON descargada y asegurada
- [ ] Key agregada como credential en Jenkins (ID: gcp-service-account-key)
- [ ] Plugins necesarios instalados
- [ ] Pipeline job creado
- [ ] RBAC configurado (opcional pero recomendado)
- [ ] Test 1-3 pasados
- [ ] Backups de configuración Jenkins
- [ ] Documentación del proceso guardada

---

## 📋 Troubleshooting

### **Error: "Permission denied"**

**Causa:** Service Account sin permisos suficientes

**Solución:**
```bash
# Verificar roles asignados:
gcloud projects get-iam-policy ecommerce-microservices-478116 \
    --flatten="bindings[].members" \
    --filter="bindings.members:terraform-jenkins*"

# Agregar role si falta:
gcloud projects add-iam-policy-binding ecommerce-microservices-478116 \
    --member=serviceAccount:terraform-jenkins@ecommerce-microservices-478116.iam.gserviceaccount.com \
    --role=roles/container.admin
```

### **Error: "Credentials not found"**

**Causa:** ID de credential incorrecto

**Solución:**
```bash
# En Jenkins:
1. Manage Jenkins → Credentials
2. Verificar que ID sea exactamente: gcp-service-account-key
3. En Jenkinsfile, verificar:
   GCP_CREDENTIALS_FILE = credentials('gcp-service-account-key')
```

### **Error: "Terraform init failed"**

**Causa:** Backend remoto no disponible

**Solución:**
```bash
# Verificar que bucket de GCS existe:
gsutil ls gs://ecommerce-terraform-state-ssd/

# Si no existe, crear:
gsutil mb gs://ecommerce-terraform-state-ssd/
gsutil versioning set on gs://ecommerce-terraform-state-ssd/
```

### **Error: "JOB timeout"**

**Causa:** Timeout de 1 hora insuficiente

**Solución:**

En Jenkinsfile.infrastructure, cambiar:
```groovy
options {
    timeout(time: 2, unit: 'HOURS')  // Aumentar a 2 horas
}
```

---

## 📝 Próximos Pasos

Una vez configurado Jenkins:

1. ✅ Ejecutar Jenkinsfile.infrastructure (test)
2. ✅ Crear infraestructura DEV
3. ✅ Crear infraestructura STAGE
4. ⏳ Crear Jenkinsfile.dev (aplicación)
5. ⏳ Integrar con Git webhooks
6. ⏳ Agregar notificaciones

---

## 📞 Soporte

**Problemas con Jenkins:**
- https://www.jenkins.io/doc/

**Problemas con GCP:**
- https://cloud.google.com/docs

**Problemas con Terraform:**
- https://registry.terraform.io/providers/hashicorp/google/latest

---

**Última actualización:** Noviembre 2024
**Versión:** 1.0
**Estado:** ✅ Production Ready
