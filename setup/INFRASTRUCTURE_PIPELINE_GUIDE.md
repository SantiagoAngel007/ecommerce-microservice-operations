# 🏗️ Guía de Uso: Jenkinsfile.infrastructure

## Introducción

El **Jenkinsfile.infrastructure** es un pipeline especializado en gestionar la infraestructura en GCP usando Terraform.

⚠️ **IMPORTANTE:**
- Este pipeline se ejecuta **MANUALMENTE** (no automático)
- Requiere **aprobación manual** antes de aplicar cambios
- Solo para cambios de infraestructura (VPC, GKE, Cloud SQL, etc.)
- NO se ejecuta con cada commit de código

---

## 📋 Características

✅ **Seguro:**
- Aprobación manual requerida
- Doble confirmación para producción
- Validación de permisos por grupo
- Audit logging de todos los cambios

✅ **Inteligente:**
- Plan antes de aplicar
- Muestra cambios detectados
- Idempotente (no repite cambios)
- Rollback fácil

✅ **Observable:**
- Logs detallados
- Artifacts guardados para auditoría
- Outputs exportados para otros pipelines
- Notificaciones de éxito/error

---

## 🚀 Cómo Usar

### **CASO 1: Crear infraestructura por primera vez (DEV)**

**Situación:** Primera vez levantando el ambiente dev

**Pasos:**

1. **Abrir Jenkins**
   ```
   http://localhost:8080
   ```

2. **Buscar el job:** `ecommerce-microservice-operations` → Jenkinsfile.infrastructure

3. **Click en "Build with Parameters"**

4. **Llenar parámetros:**
   ```
   ENVIRONMENT:  dev
   ACTION:       plan     (primero revisar cambios)
   AUTO_APPROVE: false
   EXTRA_VARS:   (dejar vacío)
   ```

5. **Click en "Build"**

6. **Revisar el plan**
   - Verá en los logs qué recursos se crearán
   - Revisará: VPC, GKE, Cloud SQL, etc.

7. **Una vez validado, volver a ejecutar con `apply`:**
   ```
   ENVIRONMENT:  dev
   ACTION:       apply    (ahora sí aplicar)
   AUTO_APPROVE: true     (para dev, si confías)
   ```

8. **Aprobar cuando pida (si AUTO_APPROVE=false)**
   - Jenkins mostrará un cuadro de aprobación
   - Click en "Aprobar cambios"

9. **Esperar a que termine**
   - GKE tarda ~15-20 minutos en crearse
   - Ver logs en tiempo real

10. **Usar outputs para otros pipelines**
    - Outputs guardados en `terraform.env`
    - Se usan automáticamente en Jenkinsfile.dev

**Output esperado:**
```
✅ PIPELINE DE INFRAESTRUCTURA COMPLETADO
Ambiente: dev
Acción: apply
Proyecto: ecommerce-microservices-478116
Región: southamerica-east1

Outputs disponibles:
GKE_CLUSTER_NAME=ecommerce-dev-cluster
ARTIFACT_REGISTRY=southamerica-east1-docker.pkg.dev/...
GCP_REGION=southamerica-east1
```

---

### **CASO 2: Revisar cambios sin aplicar**

**Situación:** Quieres ver qué cambios haría Terraform antes de aplicar

**Pasos:**

1. Configurar parámetros:
   ```
   ENVIRONMENT:  dev/stage/prod
   ACTION:       plan
   AUTO_APPROVE: false
   ```

2. Click "Build"

3. Revisar los logs:
   ```
   📋 CAMBIOS PROPUESTOS PARA DEV:
   ============================================
   Recursos que serán creados/modificados/destruidos:
   + google_compute_network.vpc (crear)
   + google_container_cluster.primary (crear)
   + google_sql_database_instance.instance (crear)
   ...
   ```

4. **Sin aprobación requerida** (solo `plan`)

5. Luego ejecutar con `apply` si los cambios se ven bien

---

### **CASO 3: Cambiar parámetros de infraestructura**

**Situación:** Necesitas más memoria en el cluster GKE

**Pasos:**

1. **Editar terraform.tfvars en el repo:**
   ```bash
   cd terraform/environments/dev
   nano terraform.tfvars
   ```

2. **Cambiar el parámetro:**
   ```hcl
   gke_machine_type = "e2-standard-8"  # (era e2-standard-4)
   ```

3. **Commit a Git:**
   ```bash
   git add .
   git commit -m "aumentar memoria del cluster a e2-standard-8"
   git push
   ```

4. **Ejecutar Jenkinsfile.infrastructure:**
   ```
   ENVIRONMENT: dev
   ACTION:      plan
   ```

5. **Revisar cambios:**
   ```
   Recursos que serán modificados:
   ~ google_container_node_pool.primary (cambiar machine_type)
   ```

6. **Aprobar y aplicar:**
   ```
   ACTION: apply
   ```

7. **GCP actualiza el cluster** (sin downtime de aplicación)

---

### **CASO 4: Destruir infraestructura (Limpieza)**

**Situación:** Terminar un ambiente (ej: dev cuando no se usa más)

**Pasos:**

1. **Ejecutar pipeline:**
   ```
   ENVIRONMENT: dev
   ACTION:      destroy
   ```

2. **Dos confirmaciones manuales:**
   - Primera: en Jenkins UI
   - Segunda: en la terminal del pipeline (escribe "destroy")

3. **Esperar a que se destruya**
   - GKE tarda ~5-10 minutos en destruirse

4. **Verificar en GCP Console:**
   - VPC eliminada
   - GKE eliminado
   - Cloud SQL eliminada

⚠️ **DATOS PERDIDOS:** No se pueden recuperar

---

## 📊 Flujos de Trabajo por Ambiente

### **DESARROLLO (dev)**

```
Semana 1:
1. terraform plan   → revisar cambios
2. terraform apply  → crear infraestructura (AUTO_APPROVE=true OK)
3. Desarrollar aplicación

Semana 2-4:
1. terraform plan   → revisar cambios (si hay)
2. terraform apply  → aplicar si hay cambios (automático)
   ELSE: nada (infraestructura estable)

Fin del proyecto:
1. terraform destroy → limpiar (AUTO_APPROVE=false, doble confirmación)
```

### **STAGING (stage)**

```
Antes de cada release importante:
1. terraform plan   → revisar cambios
2. Requiere aprobación manual
3. terraform apply  → aplicar cambios
4. Ejecutar Jenkinsfile.stage para actualizar aplicación
```

### **PRODUCCIÓN (prod)**

```
MUY RARAMENTE:
1. terraform plan   → revisar cambios
2. Requiere aprobación de 2+ personas
3. terraform apply  → aplicar cambios
4. Ejecutar Jenkinsfile.prod para actualizar aplicación

⚠️ Todos los cambios en PROD requieren:
  - Documentación
  - Planning
  - Aprobación ejecutiva
  - Ventana de mantenimiento programada
```

---

## 🔒 Seguridad y Permisos

### **Quién puede ejecutar qué:**

| Ambiente | Usuario | Aprobación | Auto-approve |
|----------|---------|-----------|--------------|
| **dev** | Cualquiera | No (solo info) | ✅ Sí |
| **stage** | DevOps | Sí (manual) | ❌ No |
| **prod** | DevOps Lead | Sí (doble) | ❌ No |

### **Permisos en Jenkins:**

```groovy
// Solo miembros de 'devops-team' pueden cambiar prod
if (ENVIRONMENT == 'prod') {
    requiere grupo: devops-team
}
```

---

## 📊 Monitoreo y Logs

### **Ver logs en tiempo real:**

1. Click en el build en Jenkins
2. Click en "Console Output"
3. Ver en vivo cómo progresa Terraform

### **Archivos guardados (artifacts):**

```
Jenkins Artifacts:
├── plan-output.txt           (qué cambios haría)
├── tfplan-output.txt         (detalles del plan)
├── terraform-outputs.json    (outputs de Terraform)
├── terraform.env             (variables para otros pipelines)
├── terraform.log             (logs de debugging)
└── terraform.tfvars          (variables usadas)
```

### **Acceder a artifacts:**

1. En Jenkins: Build → Artifacts
2. Descargar archivos para review o auditoría

---

## 🐛 Troubleshooting

### **Error: "Authentication failed"**

**Causa:** Credenciales de GCP no configuradas

**Solución:**
```bash
# En Jenkins:
1. Manage Jenkins → Credentials
2. Add credential "gcp-service-account-key"
3. Subir archivo gcp-key.json
```

### **Error: "Terraform state locked"**

**Causa:** Otro pipeline está modificando infraestructura

**Solución:**
```bash
# Esperar a que termine el otro pipeline
# O desbloquear manualmente:
gcloud storage rm gs://bucket/path/terraform.tfstate.lock
```

### **Error: "Quota exceeded in GCP"**

**Causa:** Límites de recursos alcanzados

**Solución:**
```bash
# En GCP Console:
1. APIs & Services → Quotas
2. Buscar el servicio que falla
3. Solicitar aumento de cuota
4. Esperar a que GCP apruebe
```

### **Error: "Resource already exists"**

**Causa:** Recurso en GCP no sincronizado con Terraform

**Solución:**
```bash
# Sincronizar estado:
terraform import google_compute_network.vpc projects/{ID}/global/networks/{NAME}

# O versión más drástica:
terraform state rm google_compute_network.vpc
terraform import google_compute_network.vpc ...
```

---

## 📋 Checklist Pre-Ejecución

Antes de ejecutar **CUALQUIER** pipeline:

- [ ] ¿Es el ambiente correcto? (dev/stage/prod)
- [ ] ¿Revisé los cambios en `terraform.tfvars`?
- [ ] ¿Ejecuté `plan` primero antes de `apply`?
- [ ] ¿Tengo backups si es producción?
- [ ] ¿Notifiqué al equipo de cambios?
- [ ] ¿Puedo rollback si algo falla?

---

## 🔄 Integración con Otros Pipelines

### **De Jenkinsfile.infrastructure a Jenkinsfile.dev:**

El archivo `terraform.env` se exporta automáticamente:

```groovy
// En Jenkinsfile.dev:
stage('Load Infrastructure Outputs') {
    steps {
        sh '''
            # Cargar outputs de Terraform
            source ${WORKSPACE}/terraform.env

            # Usar cluster de Terraform
            kubectl cluster-info --cluster=${GKE_CLUSTER_NAME}
        '''
    }
}
```

---

## 📞 Soporte

Si algo falla:

1. **Revisar logs:** Jenkins Build → Console Output
2. **Revisar artifacts:** Jenkins Build → Artifacts
3. **Documentación:** Leer main.tf en terraform/
4. **Terraform docs:** https://registry.terraform.io/providers/hashicorp/google/latest
5. **Contactar DevOps:** Equipo de DevOps

---

## 📝 Auditoría

Todos los cambios se registran:

```bash
# Ver historial de cambios:
git log --oneline terraform/

# Ver quién aprobó:
Jenkins Build → Logs → "Approved by: user@example.com"

# Ver cambios exactos:
Jenkins Artifacts → plan-output.txt
```

---

## 🎯 Resumen Rápido

```bash
# PLAN (sin cambiar nada):
BUILD WITH PARAMETERS:
  ENVIRONMENT: dev
  ACTION:      plan
  → Muestra qué cambiaría

# APPLY (crear/actualizar):
BUILD WITH PARAMETERS:
  ENVIRONMENT: dev
  ACTION:      apply
  → Crea/actualiza recursos
  → Requiere aprobación
  → Tarda 15-20 min

# DESTROY (eliminar todo):
BUILD WITH PARAMETERS:
  ENVIRONMENT: dev
  ACTION:      destroy
  → Elimina todos recursos
  → Requiere doble confirmación
  → ⚠️ DATOS PERDIDOS
```

---

**Última actualización:** Noviembre 2024
**Versión:** 1.0
**Estado:** ✅ Production Ready
