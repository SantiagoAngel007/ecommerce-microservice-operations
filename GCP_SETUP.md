# Configuración de GCP - Pasos Previos

## 📋 PASO 1: CREAR CUENTA Y PROYECTO EN GCP

### 1.1 Crear cuenta (si no tienes)

1. Ve a https://console.cloud.google.com/
2. Haz clic en "Crear cuenta" (si no tienes)
3. Completa los datos personales
4. Ingresa método de pago (Google no te cobrará sin autorización explícita)
5. Activa el Free Trial (crédito de $300 por 90 días)

### 1.2 Crear un nuevo proyecto

6. En la consola de GCP, haz clic en el selector de proyecto (arriba a la izquierda)
7. Haz clic en "Nuevo Proyecto"
8. Nombre: ecommerce-microservices (o similar)
9. Organización: (dejar en blanco si es personal)
10. Ubicación: (dejar por defecto)
11. Clic en "Crear"
12. Espera a que se cree el proyecto (1-2 minutos)
13. Selecciona el proyecto recién creado

---

## 🔑 PASO 2: HABILITAR APIs NECESARIAS

Necesitas habilitar estas APIs en GCP para que Terraform funcione:

### 2.1 Habilitar APIs desde la consola

14. Dirígete a: APIs & Services → Library
15. Busca y habilita cada una de estas APIs:

| API                        | Propósito                            |
|----------------------------|--------------------------------------|
| Kubernetes Engine API      | Para crear GKE clusters              |
| Compute Engine API         | Para instancias VM, firewalls, VPC   |
| Cloud SQL Admin API        | Para bases de datos PostgreSQL/MySQL |
| Cloud Resource Manager API | Para gestionar recursos              |
| Service Networking API     | Para networking                      |
| Cloud Storage API          | Para buckets S3 (backend remoto)     |
| Artifact Registry API      | Para container registry privado      |
| Cloud Logging API          | Para logs y monitoreo                |
| Cloud Monitoring API       | Para métricas y alertas              |
| Secret Manager API         | Para gestión de secretos             |

### Comandos alternativos (si tienes gcloud CLI instalado):

```bash
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  secretmanager.googleapis.com
```

---

## 👤 PASO 3: CREAR CUENTA DE SERVICIO (Service Account)

Terraform necesita credenciales para autenticarse en GCP. Usaremos una Service Account:

### 3.1 Crear Service Account desde la consola

16. Ve a: APIs & Services → Credentials
17. Haz clic en "Crear Credenciales"
18. Selecciona "Service Account"
19. Completa los campos:
    - Nombre: terraform-sa
    - ID: terraform-sa (se genera automáticamente)
    - Descripción: Service Account para Terraform IaC
20. Haz clic en "Crear y Continuar"

### 3.2 Asignar permisos a la Service Account

En el paso "Grant roles to service account":

21. Haz clic en "Seleccionar un rol"
22. Asigna estos roles (búscalos y selecciónalos):
    - Editor - Para acceso completo (desarrollo)
    - Kubernetes Engine Admin - Para GKE
    - Compute Admin - Para instancias
    - Cloud SQL Admin - Para bases de datos
    - Service Account User - Para usar la cuenta

O simplemente: Selecciona Owner (más permisivo, solo para desarrollo)

23. Haz clic en "Continuar"
24. En la siguiente pantalla, haz clic en "Hecho"

### 3.3 Crear y descargar la clave JSON

25. Ve a: APIs & Services → Service Accounts
26. Haz clic en la Service Account terraform-sa que creaste
27. Ve a la pestaña "Keys"
28. Haz clic en "Agregar Clave" → "Crear Nueva Clave"
29. Selecciona JSON
30. Se descargará un archivo terraform-sa-xxxx.json
31. IMPORTANTE: Guarda este archivo en un lugar seguro
    - Rename a gcp-key.json
    - Guarda en: terraform/credentials/gcp-key.json
    - Nunca lo subas a Git (agrega a .gitignore)

### Alternativa con gcloud CLI:

```bash
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

---

## ☁️ PASO 4: CREAR BUCKET DE CLOUD STORAGE PARA BACKEND REMOTO

Terraform necesita un lugar seguro para almacenar el estado:

### 4.1 Crear bucket manualmente

32. Ve a: Cloud Storage → Buckets
33. Haz clic en "Crear un bucket"
34. Completa:
    - Nombre: ecommerce-terraform-state (debe ser globalmente único)
    - Ubicación: Selecciona la región más cercana a ti (ej: us-central1)
    - Clase de almacenamiento: Standard
    - Control de acceso: Uniforme
    - Encrypting: Habilita Google-managed encryption
35. Haz clic en "Crear"

### 4.2 Habilitar versionado (importante para seguridad)

36. Entra al bucket que creaste
37. Ve a Configuración
38. En "Versionado de objetos", haz clic en "Editar"
39. Selecciona "Habilitado"
40. Guarda cambios

### Alternativa con gcloud CLI:

```bash
gsutil mb gs://ecommerce-terraform-state
gsutil versioning set on gs://ecommerce-terraform-state
```

---

## 🌍 PASO 5: RECOPILAR INFORMACIÓN NECESARIA

Una vez completados los pasos anteriores, recopila esta información:

### 📝 INFORMACIÓN A RECOPILAR:

41. PROJECT_ID de GCP
    → Ve a: Google Cloud Console → Configuración del Proyecto
    → Ejemplo: "ecommerce-microservices-123456"

42. REGIÓN POR DEFECTO
    → Ej: "us-central1" o "southamerica-east1" (si estás en LATAM)

43. BUCKET DE TERRAFORM STATE
    → Nombre: "ecommerce-terraform-state"
    → Ubicación: la región que elegiste

44. SERVICE ACCOUNT EMAIL
    → Formato: "terraform-sa@PROJECT_ID.iam.gserviceaccount.com"
    → Encuentralo en: APIs & Services → Service Accounts

45. RUTA AL ARCHIVO DE CREDENCIALES
    → Donde guardaste: "gcp-key.json"

---

## ✅ CHECKLIST PRE-TERRAFORM

Antes de empezar con Terraform, verifica que hayas completado:

- [ ] Cuenta de GCP creada y acceso a console.cloud.google.com
- [ ] Proyecto "ecommerce-microservices" creado
- [ ] 10 APIs habilitadas (ver paso 2)
- [ ] Service Account "terraform-sa" creada
- [ ] Roles asignados a la Service Account (Editor o similar)
- [ ] Archivo JSON de credenciales descargado y guardado seguro
- [ ] Bucket de Cloud Storage creado para estado
- [ ] Versionado habilitado en el bucket
- [ ] Información recopilada (PROJECT_ID, REGION, etc.)

---

## 🔍 VERIFICACIÓN RÁPIDA CON GCLOUD CLI

Si tienes gcloud CLI instalado, puedes verificar:

```bash
# Configurar proyecto activo
gcloud config set project YOUR_PROJECT_ID

# Verificar Service Account
gcloud iam service-accounts list

# Verificar APIs habilitadas
gcloud services list --enabled

# Verificar bucket creado
gsutil ls
```

---

## ⚠️ NOTAS IMPORTANTES

1. **Costo**: Estás en Free Trial ($300 crédito). Monitoring del costo:
   - Ve a: Facturación → Resumen para ver gastos
   - GKE tiene algunas capas gratuitas iniciales
   - Cloud SQL tiene tier gratuito limitado

2. **Seguridad**:
   - Nunca subas gcp-key.json a Git
   - Usa variables de entorno: export GOOGLE_APPLICATION_CREDENTIALS="path/to/gcp-key.json"
   - Guarda el archivo en lugar seguro (no en documentos públicos)

3. **Región**:
   - Elige la región más cercana geográficamente
   - Ej: si estás en Colombia → southamerica-east1 (Brasil)

