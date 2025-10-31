# Guía Rápida: Solución de Certificado TLS en Jenkins + Kubernetes

## 🎯 El Problema (En 30 segundos)

```
Error: Unable to connect to the server: tls: failed to verify certificate:
x509: certificate signed by unknown authority
```

**Causa**: Tu kubeconfig tiene un certificado auto-firmado que kubectl no confía.

## ✅ La Solución (Ya Aplicada)

El Jenkinsfile.stage ahora **deshabilita automáticamente** la verificación de certificados TLS en todos los stages que usan kubectl.

```bash
# Lo que el pipeline hace automáticamente ahora:
mkdir -p /tmp/k8s-jenkins
cp ${KUBECONFIG} /tmp/k8s-jenkins/kubeconfig
kubectl config set-cluster kubernetes \
    --kubeconfig=/tmp/k8s-jenkins/kubeconfig \
    --insecure-skip-tls-verify=true
export KUBECONFIG=/tmp/k8s-jenkins/kubeconfig
```

## 🚀 Ahora Puedes Ejecutar el Pipeline

### En Jenkins:
1. Abre Jenkins
2. Busca el job para `Jenkinsfile.stage`
3. Haz clic en **"Build with Parameters"**
4. Configura:
   - ENVIRONMENT: `stage`
   - SETUP_NAMESPACE: `false` (si ya existe)
   - RUN_TESTS: `true` (para ejecutar pruebas)
   - DEPLOY_INFRA: `false` (a menos que lo necesites)
5. Haz clic en **Build**

### Stages que se ejecutarán:
```
✅ 1. Checkout - Code
✅ 2. Checkout - Operations
✅ 3. Setup Stage Namespace (si seleccionas)
✅ 3a. Check Docker Images
✅ 4. Compile Services (si images no existen)
✅ 5. Build Docker Images (si images no existen)
✅ 6. Push Docker Hub (si images no existen)
✅ 7. Skip Build (si images existen)
✅ 8. Check Kubernetes ← AQUÍ SE FIX TLS
✅ 8a. Setup Docker Secret
✅ 9. Deploy Infraestructura (si seleccionas)
✅ 10. Deploy to Kubernetes ← AQUÍ SE FIX TLS
✅ 11. Verify Deployment ← AQUÍ SE FIX TLS
✅ 12. Get Service IPs ← AQUÍ SE FIX TLS
✅ 13. Run Unit Tests
✅ 14. Run Integration Tests ← AQUÍ SE FIX TLS
✅ 15. Run Performance Tests ← AQUÍ SE FIX TLS
✅ 16. Analyze Test Results
✅ 17. Archive Test Results
```

## 🔍 Verificación (Opcional)

Para verificar que funciona **localmente** antes de Jenkins:

```bash
# 1. Exporta tu kubeconfig
export KUBECONFIG=/ruta/a/tu/kubeconfig

# 2. Prueba sin la solución (fallará)
kubectl cluster-info
# Error: Unable to connect...

# 3. Aplica la solución
mkdir -p /tmp/k8s-jenkins
cp $KUBECONFIG /tmp/k8s-jenkins/kubeconfig
kubectl config set-cluster kubernetes \
    --kubeconfig=/tmp/k8s-jenkins/kubeconfig \
    --insecure-skip-tls-verify=true

# 4. Prueba con la solución (funcionará)
export KUBECONFIG=/tmp/k8s-jenkins/kubeconfig
kubectl cluster-info
# ✓ Kubernetes control plane is running at...
```

## 📊 Qué Hace el Pipeline (Resumen)

```
┌─────────────────────────────────────────────┐
│  ETAPA 1: CÓDIGO Y COMPILACIÓN             │
│  - Clona código y operaciones              │
│  - Compila 8 microservicios                │
│  - Construye imágenes Docker               │
│  - Sube a Docker Hub                       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  ETAPA 2: KUBERNETES [TLS FIXED ✅]        │
│  - Verifica conexión al cluster            │
│  - Crea namespace y secrets                │
│  - Despliega 8 microservicios              │
│  - Verifica que pods estén listos          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  ETAPA 3: PRUEBAS [TLS FIXED ✅]           │
│  - Pruebas unitarias (Maven)               │
│  - Pruebas de integración                  │
│  - Pruebas de rendimiento (Locust)         │
│  - Análisis y archivado de resultados      │
└─────────────────────────────────────────────┘
```

## 🛠️ Parámetros del Pipeline

| Parámetro | Valores | Predeterminado | Función |
|-----------|---------|-----------------|---------|
| ENVIRONMENT | stage | stage | Ambiente destino |
| SETUP_NAMESPACE | true/false | false | ¿Crear namespace desde cero? |
| RUN_TESTS | true/false | true | ¿Ejecutar pruebas? |
| DEPLOY_INFRA | true/false | false | ¿Desplegar Config Server y Zipkin? |

## 📝 Ejemplo de Uso

### Escenario 1: Despliegue Completo (Primer Run)
```
ENVIRONMENT: stage
SETUP_NAMESPACE: true
RUN_TESTS: true
DEPLOY_INFRA: true
```
Ejecuta TODOS los stages incluyendo compilación, namespace setup, y pruebas.

### Escenario 2: Actualizar Código (Después compilado)
```
ENVIRONMENT: stage
SETUP_NAMESPACE: false
RUN_TESTS: true
DEPLOY_INFRA: false
```
Salta compilación (images ya existen), despliega, y ejecuta pruebas.

### Escenario 3: Solo Pruebas (Debug)
```
ENVIRONMENT: stage
SETUP_NAMESPACE: false
RUN_TESTS: true
DEPLOY_INFRA: false
```
Despliega servicios existentes y ejecuta pruebas.

## ⚠️ Troubleshooting Rápido

| Error | Causa | Solución |
|-------|-------|----------|
| `kubeconfig not found` | Credencial no configurada en Jenkins | Ve a Jenkins → Credentials → System → Global credentials → Crea "Secret file" con ID `kubeconfig` |
| `kubectl: command not found` | kubectl no está instalado | Instala kubectl en el Jenkins agent |
| `mkdir: cannot create directory` | `/tmp` no existe o no es escribible | `mkdir -p /tmp/k8s-jenkins && chmod 755 /tmp/k8s-jenkins` |
| `tls: failed to verify certificate` | La solución no se aplicó | Asegúrate de estar usando la versión actualizada del Jenkinsfile.stage |

## 📚 Documentación Detallada

Para información completa, consulta:
- **`KUBERNETES_CERTIFICATE_SOLUTIONS.md`** - Todas las opciones disponibles
- **`KUBERNETES_TLS_FIX_APPLIED.md`** - Detalles técnicos de la implementación

## ✅ Checklist Pre-Ejecución

Antes de ejecutar el pipeline, verifica:

- [ ] Jenkins está accesible y funcionando
- [ ] El plugin de Git está instalado en Jenkins
- [ ] Existe credencial `kubeconfig` en Jenkins (Secret file)
- [ ] Existe credencial `docker-hub-password` en Jenkins
- [ ] Existe credencial `docker-username` en Jenkins
- [ ] Existe credencial `docker-token` en Jenkins
- [ ] Existe credencial `docker-email` en Jenkins
- [ ] kubectl está instalado en el Jenkins agent
- [ ] Docker está disponible en el Jenkins agent
- [ ] El kubeconfig es válido:
  ```bash
  kubectl config view --kubeconfig=/ruta/a/kubeconfig
  ```

## 🎉 ¡Listo!

El Jenkinsfile.stage está completamente configurado y listo para ejecutarse.

**Ahora puedes:**
1. ✅ Ejecutar el pipeline desde Jenkins
2. ✅ Ver los logs en tiempo real
3. ✅ Desplegar a Kubernetes sin errores de certificado TLS
4. ✅ Ejecutar pruebas automáticas
5. ✅ Archivar resultados

¡Que disfrutes del pipeline! 🚀

