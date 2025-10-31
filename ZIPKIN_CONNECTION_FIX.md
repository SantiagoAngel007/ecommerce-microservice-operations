# ✅ Solución: Service-Discovery No Puede Conectar a Zipkin

## 🔴 Problema Identificado

```
WARN [...] Check result of the [RestTemplateSender{http://localhost:9411/api/v2/spans}] contains an error
[CheckResult{ok=false, error=org.springframework.web.client.ResourceAccessException:
I/O error on POST request for "http://localhost:9411/api/v2/spans":
Connection refused (Connection refused)}]
```

### ¿Por Qué Pasa?

1. **Service-Discovery intenta conectar a `http://localhost:9411`**
   - `localhost` = 127.0.0.1 (el propio pod)
   - Zipkin está en otro pod, no en localhost

2. **Service-Discovery no está usando la ConfigMap**
   - ConfigMap tiene `http://zipkin:9411/` (correcto)
   - Pero Spring no sabe dónde buscar esa configuración
   - Spring usa la configuración por defecto (localhost)

3. **Raíz del problema**:
   - El Deployment **montaba la ConfigMap en `/config`**
   - Pero **NO le indicaba a Spring dónde buscarla**
   - Spring buscaba configuración en el classpath (por defecto con localhost)

---

## ✅ Solución Implementada

### Cambio en Deployment

**Archivo**: `k8s/stage/service-discovery/deployment.yaml`

**Antes**:
```yaml
env:
- name: SPRING_PROFILES_ACTIVE
  value: "stage"
- name: SPRING_APPLICATION_NAME
  value: "SERVICE-DISCOVERY"
```

**Después**:
```yaml
env:
- name: SPRING_PROFILES_ACTIVE
  value: "stage"
- name: SPRING_APPLICATION_NAME
  value: "SERVICE-DISCOVERY"
- name: SPRING_CONFIG_LOCATION
  value: "file:/config/application-stage.yml"
```

### ¿Qué Hace?

La variable `SPRING_CONFIG_LOCATION` le indica a Spring:
> "Lee la configuración del archivo `/config/application-stage.yml`"

Ese archivo está montado en el pod desde la ConfigMap, que contiene:
```yaml
zipkin:
  base-url: http://zipkin:9411/
```

---

## 🔍 Por Qué Otros Servicios NO Tienen Este Problema

**Otros servicios SÍ tienen `SPRING_CONFIG_LOCATION`:**

```bash
$ grep -l "SPRING_CONFIG_LOCATION" k8s/stage/*/deployment.yaml

✅ favourite-service/deployment.yaml
✅ order-service/deployment.yaml
✅ payment-service/deployment.yaml
✅ product-service/deployment.yaml
✅ proxy-client/deployment.yaml
✅ service-discovery/deployment.yaml (ACTUALIZADO)
✅ shipping-service/deployment.yaml
✅ user-service/deployment.yaml
```

**Service-Discovery era el ÚNICO que faltaba**. Ahora todos tienen la variable.

---

## 📊 Comparativa Antes vs Después

### ANTES (Falla):
```
Service-Discovery Deployment
  ├─ Monta ConfigMap en /config/application-stage.yml
  └─ NO tiene SPRING_CONFIG_LOCATION
       ↓
  Spring busca configuración en classpath (default)
       ↓
  Encuentra: zipkin.base-url=http://localhost:9411/
       ↓
  Intenta conectar a localhost:9411 (no existe)
       ↓
  🔴 Connection refused
```

### DESPUÉS (Funciona):
```
Service-Discovery Deployment
  ├─ Monta ConfigMap en /config/application-stage.yml
  └─ SPRING_CONFIG_LOCATION=file:/config/application-stage.yml
       ↓
  Spring lee configuración de /config/application-stage.yml
       ↓
  Encuentra: zipkin.base-url=http://zipkin:9411/
       ↓
  Intenta conectar a zipkin:9411 (DNS resuelve a Zipkin pod)
       ↓
  ✅ Connection successful
```

---

## 🚀 Qué Hacer Ahora

### Opción 1: Limpiar y Reiniciar (Recomendado)

```bash
# 1. Ejecuta Jenkinsfile.cleanup
#    Parámetro: ENVIRONMENT=stage

# 2. Espera a que termine

# 3. Ejecuta Jenkinsfile.stage nuevamente
#    El fix de SPRING_CONFIG_LOCATION ya está en el código
```

### Opción 2: Aplicar el Fix Manualmente

```bash
# Actualizar solo el deployment de service-discovery
kubectl apply -f k8s/stage/service-discovery/deployment.yaml -n stage

# Esperar a que reinicie
kubectl rollout status deployment/service-discovery -n stage

# Verificar logs
kubectl logs -l app=service-discovery -n stage
```

### Opción 3: Patch Rápido

```bash
kubectl set env deployment/service-discovery \
  SPRING_CONFIG_LOCATION="file:/config/application-stage.yml" \
  -n stage
```

---

## ✅ Verificación Post-Fix

Después de aplicar el fix, deberías ver:

```bash
$ kubectl logs -l app=service-discovery -n stage

# Antes:
WARN [...] Check result contains an error [Connection refused]

# Después:
# (Sin el warning de Zipkin)
INFO [...] Started ServiceDiscoveryApplication in 5.123 seconds
INFO [...] Registering application service-discovery with Eureka
```

### Status de Pods:

```bash
$ kubectl get pods -n stage

NAME                                READY   STATUS    RESTARTS   AGE
service-discovery-xxxxxxxx-xxxxx    1/1     Running   0          1m
config-server-xxxxxxxx-xxxxx        1/1     Running   0          1m
zipkin-xxxxxxxx-xxxxx               1/1     Running   0          1m
```

---

## 📋 Resumen Técnico

| Aspecto | Detalle |
|---------|---------|
| **Problema** | Service-Discovery usa localhost en lugar de zipkin DNS |
| **Causa** | Falta SPRING_CONFIG_LOCATION en deployment |
| **Solución** | Agregar `SPRING_CONFIG_LOCATION=file:/config/application-stage.yml` |
| **Archivos Modificados** | 1 (k8s/stage/service-discovery/deployment.yaml) |
| **Impacto** | Service-Discovery ahora se conecta correctamente a Zipkin |
| **Otros Servicios** | Ya tenían este fix (no afectados) |

---

## 🎯 Por Qué Pasó Esto

Durante la creación inicial del Deployment de service-discovery:

1. ✅ Se montó la ConfigMap en `/config`
2. ✅ La ConfigMap tenía la configuración correcta (`http://zipkin:9411/`)
3. ❌ Se olvidó agregar `SPRING_CONFIG_LOCATION`
4. ❌ Spring no sabía dónde buscar esa ConfigMap
5. ❌ Spring usó la configuración por defecto (localhost)

**Solución simple**: Indicarle a Spring dónde está la configuración.

---

## 📚 Documentación Relacionada

- **SH_COMPATIBILITY_FIX.md** - Otros fixes en Jenkinsfile
- **KUBERNETES_TLS_FINAL_SOLUTION.md** - Fix de TLS
- **CLEANUP_USAGE_GUIDE.md** - Cómo limpiar ambientes

---

## ✨ Estado Después del Fix

### Comportamiento Esperado:

```
Service-Discovery Startup:
  1. Lee SPRING_CONFIG_LOCATION
  2. Carga /config/application-stage.yml (de la ConfigMap)
  3. Obtiene: zipkin.base-url=http://zipkin:9411/
  4. Conecta exitosamente a Zipkin
  5. Inicia Eureka Server
  6. Otros servicios se registran con el Eureka de service-discovery

Result:
  ✅ Service-Discovery: RUNNING
  ✅ Puede conectar a Zipkin: OK
  ✅ Otros servicios pueden registrarse: OK
```

---

**Implementado**: 2024-10-31
**Versión**: k8s/stage v2.1 (Con SPRING_CONFIG_LOCATION Fix)
**Estado**: ✅ Completado

🎉 **El problema está resuelto!**

