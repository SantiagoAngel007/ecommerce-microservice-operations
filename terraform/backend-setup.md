# Configuración de Backend Remoto para Terraform

Este documento describe cómo configurar el backend remoto en Google Cloud Storage (GCS).

## Paso 1: Inicializar con Backend Local (Primero)

Antes de configurar el backend remoto, inicializa Terraform localmente:

```bash
cd terraform
terraform init
```

## Paso 2: Crear el Bucket (Ya está creado)

El bucket `ecommerce-terraform-state-ssd` ya fue creado en GCP.

Verifica que exista:
```bash
gsutil ls gs://ecommerce-terraform-state-ssd
```

## Paso 3: Configurar Backend Remoto

Una vez que hayas validado la infraestructura localmente, configura el backend remoto editando `backend.tf`:

### Para Desarrollo:
```hcl
terraform {
  backend "gcs" {
    bucket  = "ecommerce-terraform-state-ssd"
    prefix  = "dev"
    credentials = "./credentials/gcp-key.json"
  }
}
```

### Para Staging:
```hcl
terraform {
  backend "gcs" {
    bucket  = "ecommerce-terraform-state-ssd"
    prefix  = "stage"
    credentials = "./credentials/gcp-key.json"
  }
}
```

### Para Producción:
```hcl
terraform {
  backend "gcs" {
    bucket  = "ecommerce-terraform-state-ssd"
    prefix  = "prod"
    credentials = "./credentials/gcp-key.json"
  }
}
```

## Paso 4: Migrar el Estado Local al Backend Remoto

Una vez que `backend.tf` esté configurado:

```bash
# Inicializa nuevamente con el nuevo backend
terraform init

# Cuando te pregunte si deseas copiar el estado existente, responde: yes
# Esto migra el estado local a GCS
```

## Paso 5: Limpiar el Estado Local (Opcional)

```bash
# Puedes eliminar el archivo local si está en otro lado
rm terraform.tfstate*
```

## Verificar Backend Remoto

```bash
# Ver el contenido del bucket
gsutil ls -r gs://ecommerce-terraform-state-ssd

# Ver el archivo de estado específico
gsutil cat gs://ecommerce-terraform-state-ssd/dev/terraform.tfstate
```

## Estructura de Estados

El bucket estará organizado así:
```
ecommerce-terraform-state-ssd/
├── dev/
│   └── terraform.tfstate          # Estado de desarrollo
├── stage/
│   └── terraform.tfstate          # Estado de staging
└── prod/
    └── terraform.tfstate          # Estado de producción
```

## Ventajas del Backend Remoto

1. **Colaboración:** Múltiples miembros del equipo pueden trabajar con el mismo estado
2. **Bloqueos:** Terraform maneja locks automáticos para evitar cambios simultáneos
3. **Versionado:** GCS mantiene un historial de versiones de los estados
4. **Seguridad:** Los estados se encriptan en reposo en GCS
5. **Disponibilidad:** Los estados están respaldados en la nube

## Troubleshooting

### Error: "Failed to get GCS bucket version"
- Verifica que las APIs estén habilitadas en GCP
- Verifica que la Service Account tenga permisos en el bucket

### Error: "Error reading state file"
- Asegúrate de que el archivo `gcp-key.json` esté en la ruta correcta
- Verifica que las credenciales sean válidas

### Error: "Access Denied"
- Verifica que la Service Account tenga el rol `roles/storage.admin`
- O como mínimo: `roles/storage.objectAdmin` y `roles/storage.legacyBucketReader`
