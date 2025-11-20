# Guía: Estructura de Terraform y Archivos .gitignore

## 📁 Estructura de Carpetas Terraform

```
terraform/
├── main.tf                 # Configuración principal (VPC, GKE, Cloud SQL)
├── providers.tf            # Configuración de GCP
├── variables.tf            # Variables globales
├── outputs.tf              # Outputs del estado
├── backend.tf              # Backend remoto en GCS
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars    # Variables específicas DEV
│   │   └── backend.tf          # Backend GCS DEV
│   ├── stage/
│   │   ├── terraform.tfvars    # Variables específicas STAGE
│   │   └── backend.tf          # Backend GCS STAGE
│   └── prod/
│       ├── terraform.tfvars    # Variables específicas PROD
│       └── backend.tf          # Backend GCS PROD
└── modules/                # Módulos reutilizables (si existen)
```

## 🔑 Archivos Excluidos en .gitignore

Estos archivos **NO se suben** a git porque contienen información sensible:

```
*.tfstate                  # Estado actual de la infraestructura
*.tfstate.*                # Backups del estado
*.tfvars                   # Variables con secretos (API keys, passwords)
*.tfvars.json              # Mismo pero en JSON
.terraform/                # Dependencias descargadas
terraform.lock.hcl         # Lock file (OPCIONAL subirlo para reproducibilidad)
gcp-key.json               # Credenciales GCP
credentials/               # Carpeta de credenciales
*.pem, *.key, *.crt        # Certificados y claves SSH
kubeconfig*                # Archivos de configuración Kubernetes
.env, env.config           # Variables de entorno locales
```

## ✅ Cómo Crear los Archivos Necesarios

### 1. **Crear `gcp-key.json`**

Cada compañero debe obtener su propio archivo de credenciales:

```bash
# En GCP Console:
# 1. Ir a: IAM & Admin → Service Accounts
# 2. Crear una nueva Service Account o usar una existente
# 3. Crear una clave de tipo JSON
# 4. Descargar el archivo gcp-key.json
# 5. Guardarlo en: terraform/credentials/gcp-key.json
```

**Estructura esperada:**
```json
{
  "type": "service_account",
  "project_id": "ecommerce-microservices-478116",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "terraform@ecommerce-microservices-478116.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

### 2. **Crear `environments/{env}/terraform.tfvars`**

Copiar de las variables de ejemplo y completar con valores específicos:

```hcl
# environments/dev/terraform.tfvars
project_id       = "ecommerce-microservices-478116"
region            = "us-central1"
environment       = "dev"
cluster_name      = "ecommerce-dev-cluster"
cluster_nodes     = 2
machine_type      = "e2-standard-2"

# Para STAGE
# cluster_nodes     = 2
# machine_type      = "e2-standard-4"

# Para PROD
# cluster_nodes     = 3
# machine_type      = "e2-standard-4"
```

### 3. **Crear carpeta de credenciales**

```bash
mkdir -p terraform/credentials
# Colocar gcp-key.json aquí
```

## 🔄 Flujo de Inicialización

```bash
# 1. Posicionarse en el ambiente
cd terraform/environments/dev

# 2. Inicializar Terraform (descarga providers y backend)
terraform init

# 3. Validar configuración
terraform validate

# 4. Ver cambios que se harían
terraform plan

# 5. Aplicar cambios
terraform apply
```

## ⚠️ Notas Importantes

- **NO commitar** archivos con secretos (gcp-key.json, *.tfstate, *.tfvars)
- El archivo `credentials/gcp-key.json` es local a cada desarrollador
- El estado remoto está en GCS (`ecommerce-terraform-state-ssd`)
- Cada ambiente tiene su propio bucket de estado (prefijos: dev/, stage/, prod/)
- Para verificar el estado: `gsutil ls gs://ecommerce-terraform-state-ssd/`

## 📊 Variables por Ambiente

| Ambiente | Nodos | Tipo de Máquina | CIDR VPC    |
|----------|-------|-----------------|-------------|
| dev      | 2     | e2-standard-2   | 10.0.0.0/16 |
| stage    | 2     | e2-standard-4   | 10.1.0.0/16 |
| prod     | 3     | e2-standard-4   | 10.2.0.0/16 |

