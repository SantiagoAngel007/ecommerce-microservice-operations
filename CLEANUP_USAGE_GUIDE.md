# 🧹 Guía de Uso: Jenkinsfile.cleanup

## ¿Qué Hace?

El `Jenkinsfile.cleanup` **elimina completamente** un ambiente de Kubernetes (dev, stage, o prod):

1. ✅ Elimina el **namespace completo** y todos sus recursos
2. ✅ Detiene todos los **pods, servicios, y deployments**
3. ✅ Libera todos los **volúmenes y secrets**
4. ✅ Verifica que el cleanup fue exitoso

---

## 🚀 Cómo Ejecutarlo

### En Jenkins:

1. **Abre Jenkins** en tu navegador
2. **Busca el job** `Jenkinsfile.cleanup`
3. **Haz clic** en "Build with Parameters"
4. **Selecciona el ENVIRONMENT**:
   ```
   ENVIRONMENT: stage  (para limpiar stage)
   ```
5. **Haz clic** en "Build"

### Resultado:

```
✅ Stage 1: Checkout - Operations
   └─ Clona repositorio de operaciones

✅ Stage 2: Delete Namespace
   └─ 🗑️ Eliminando namespace stage...
   └─ ✓ Namespace stage eliminado

✅ Stage 3: Verify Cleanup
   └─ ✅ Verificando que el namespace fue eliminado:
   └─ ✓ Namespace no existe (limpio)
   └─ NAMESPACES ACTIVOS:
      NAME              STATUS   AGE
      default           Active   ...
      kube-node-lease   Active   ...
      kube-public       Active   ...
      kube-system       Active   ...

✅ Cleanup completado exitosamente
```

---

## ⚠️ Precaución

### ¡DESTRUCTIVO!

**Este comando elimina TODO el ambiente**:
- ✅ Todos los pods
- ✅ Todos los servicios
- ✅ Todos los deployments
- ✅ Todos los secrets
- ✅ Todos los configmaps
- ✅ La base de datos (H2 en memoria)

### **No se puede recuperar** lo que se elimine.

### ¿Cuándo Usar?

✅ **Seguro usar para**:
- Limpiar ambiente de **desarrollo** (dev)
- Limpiar ambiente de **staging** (stage)
- Reiniciar un ambiente desde cero
- Eliminar recursos antes de una reinstalación

❌ **NUNCA usar para**:
- Limpiar ambiente de **producción** (prod)
- Datos que aún necesitas
- Ambiente activo en uso

---

## 📊 Qué Elimina

Cuando ejecutas el cleanup para `stage`, se elimina:

```
Namespace: stage
├─ Deployments:
│  ├─ service-discovery
│  ├─ proxy-client
│  ├─ user-service
│  ├─ product-service
│  ├─ order-service
│  ├─ payment-service
│  ├─ favourite-service
│  ├─ shipping-service
│  ├─ config-server
│  └─ zipkin
│
├─ Services:
│  └─ (todos los servicios)
│
├─ ConfigMaps:
│  └─ (todas las configuraciones)
│
├─ Secrets:
│  └─ dockerhub-credentials (y otros)
│
└─ Pods:
   └─ (todos los pods)
```

---

## ✨ Cambios Implementados

El `Jenkinsfile.cleanup` ha sido actualizado para:

1. ✅ **Usar flag `--insecure-skip-tls-verify=true`** en todos los comandos kubectl
   - Funciona con certificados auto-firmados (Minikube, Docker Desktop, k3s)

2. ✅ **Ser compatible con `/bin/sh`**
   - Usa sintaxis POSIX pura
   - Funciona en cualquier shell

3. ✅ **Mostrar más información**
   - Verifica que el namespace fue eliminado
   - Lista namespaces activos después del cleanup

---

## 📝 Ejemplo Completo

### Escenario: Limpiar ambiente stage para reinstalar

```bash
# 1. Abre Jenkins
# 2. Ve a Jenkinsfile.cleanup
# 3. Build with Parameters
# 4. Selecciona: ENVIRONMENT = stage
# 5. Haz clic en Build
```

### Logs esperados:

```
Started by user Jenkins
Building in workspace /var/jenkins_home/workspace/ecommerce-cleanup-pipeline

Stage '1. Checkout - Operations'
  🔄 Clonando repositorio de operaciones...
  Cloning into 'ops'...
  Cloned repository

Stage '2. Delete Namespace'
  🗑️  Eliminando namespace stage...
  namespace "stage" deleted
  ✓ Namespace stage eliminado
  (espera 10 segundos)

Stage '3. Verify Cleanup'
  ✅ Verificando que el namespace fue eliminado:
  Error from server (NotFound): namespaces "stage" not found
  ✓ Namespace no existe (limpio)

  ==========================================
  NAMESPACES ACTIVOS:
  ==========================================
  NAME              STATUS   AGE
  default           Active   123d
  kube-node-lease   Active   123d
  kube-public       Active   123d
  kube-system       Active   123d

Finished: SUCCESS
✅ Cleanup completado exitosamente
```

---

## 🔄 Workflow Típico

### Desarrollo Iterativo:

```
1. Ejecutar Jenkinsfile.stage (deploy inicial)
   └─ Todo funciona ✅

2. Hacer cambios en code
   └─ Ejecutar Jenkinsfile.stage (actualiza servicios)
   └─ Pruebas ✅

3. Necesito reiniciar limpio
   └─ Ejecutar Jenkinsfile.cleanup (limpia stage)
   └─ Ejecutar Jenkinsfile.stage (deploy fresco)
   └─ Pruebas ✅
```

---

## 🛠️ Troubleshooting

### Error: "kubectl: command not found"
**Causa**: kubectl no está instalado en el Jenkins agent
**Solución**: Instala kubectl en el nodo de Jenkins

### Error: "Unable to connect to the server"
**Causa**: Kubeconfig inválido o cluster no disponible
**Solución**: Verifica que la credencial `kubeconfig` existe en Jenkins

### Error: "Namespace not found" (cuando debería existir)
**Causa**: Ya fue eliminado antes
**Solución**: Nada, es lo esperado. Puedes ejecutar Jenkinsfile.stage de nuevo

### El cleanup tarda mucho
**Causa**: Kubernetes está esperando que los pods terminen gracefully
**Solución**: Es normal. Espera a que termine (máximo 5 minutos)

---

## ✅ Seguridad

### Protecciones Implementadas

- ✅ Parámetro obligatorio `ENVIRONMENT` (debe elegirse explícitamente)
- ✅ Verification stage confirma que se eliminó
- ✅ Mensaje claro en los logs
- ✅ Sleep de 10 segundos antes de verificar

### Lo que NO Previene

- ❌ Seleccionar accidentalmente "prod" en lugar de "stage"
- ❌ Ejecutar cuando no deberías

**Recomendación**: Ten cuidado al seleccionar el ambiente. Si accidentalmente seleccionas "prod", contáctame inmediatamente.

---

## 📚 Documentación Relacionada

- **KUBERNETES_TLS_FINAL_SOLUTION.md** - Detalles del fix de TLS
- **SH_COMPATIBILITY_FIX.md** - Detalles de compatibilidad POSIX

---

## 🎯 Resumen Rápido

| Acción | Comando |
|--------|---------|
| **Limpiar stage** | `Jenkinsfile.cleanup` + `ENVIRONMENT=stage` |
| **Limpiar dev** | `Jenkinsfile.cleanup` + `ENVIRONMENT=dev` |
| **Limpiar prod** | `Jenkinsfile.cleanup` + `ENVIRONMENT=prod` |

**Tiempo de ejecución**: 1-2 minutos

**Datos eliminados**: TODO (no recuperable)

**Reversible**: No (necesitas ejecutar Jenkinsfile.stage de nuevo)

---

**Implementado**: 2024-10-31
**Versión**: Jenkinsfile.cleanup v1.0 (Con TLS Fix)
**Estado**: ✅ Listo

🧹 **¡Usa con cuidado!**

