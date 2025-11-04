# Análisis de Pruebas de Rendimiento - Payment Service

## Resumen General
- **Total de Solicitudes:** 71
- **Solicitudes Fallidas:** 46 (64.79%)
- **Duración:** 30 segundos
- **Usuarios Concurrentes:** 5

---

## Métricas Clave

### Tiempo de Respuesta
- **Promedio:** 6 ms
- **Mínimo:** 3 ms
- **Máximo:** 41 ms
- **Mediana (P50):** 5 ms
- **P95:** 18 ms
- **P99:** 20 ms

Los tiempos de respuesta son buenos, pero la variabilidad es alta (41ms máximo indica inconsistencias).

### Throughput
- **Requests por Segundo (req/s):** 2.43 req/s
- **Tasa de Errores por Segundo:** 1.57 errores/s

El throughput es muy bajo considerando solo 5 usuarios concurrentes.

### Análisis por Endpoint

| Endpoint | Total Req | Fallos | Tasa Error | Tiempo Avg |
|----------|-----------|--------|-----------|-----------|
| GET /health | 6 | 6 | 100% | 5 ms |
| POST /payments | 12 | 12 | 100% | 6 ms |
| GET /payments/{id} | 23 | 0 | 0% | 7 ms |
| GET /payments?page=* | 30 | 28 | 93.3% | 5 ms |

## Problemas Identificados

1. **Health Check fallando al 100%:** El endpoint `/actuator/health` no responde correctamente, indicando servicio inestable.

2. **POST de pagos fallando completamente:** Todas las solicitudes POST fallan (100%), bloqueando creación de transacciones.

3. **Endpoints de paginación con tasa de error del 93%:** Las búsquedas paginadas son prácticamente inutilizables.

4. **GETs individuales estables:** Solo los GET de IDs específicas funcionan sin errores.

---

# Análisis de Pruebas de Rendimiento - User Service

## Resumen General
- **Total de Solicitudes:** 71
- **Solicitudes Fallidas:** 57 (80.28%)
- **Duración:** 30 segundos
- **Usuarios Concurrentes:** 5

---

## Métricas Clave

### Tiempo de Respuesta
- **Promedio:** 8 ms
- **Mínimo:** 3 ms
- **Máximo:** 128 ms
- **Mediana (P50):** 5 ms
- **P95:** 18 ms
- **P99:** 130 ms

Alta variabilidad: máximo de 128ms indica problemas graves de consistencia.

### Throughput
- **Requests por Segundo:** 2.50 req/s
- **Tasa de Errores por Segundo:** 2.00 errores/s

Throughput muy bajo para carga mínima (5 usuarios).

### Análisis por Endpoint

| Endpoint | Total Req | Fallos | Tasa Error | Tiempo Avg |
|----------|-----------|--------|-----------|-----------|
| GET /health | 7 | 7 | 100% | 8 ms |
| POST /users | 16 | 16 | 100% | 13 ms |
| GET /users | 34 | 34 | 100% | 5 ms |
| GET /users/{id} | 14 | 0 | 0% | 6 ms |

## Errores Identificados

**Errores Principales (57 fallos totales):**
- GET /users: 34 fallos (404)
- POST /users: 16 fallos (404)
- GET /health: 7 fallos (404)

**Problema Crítico:** Todos los endpoints devuelven errores 404, sugiriendo que las rutas no están correctamente mapeadas o el servicio no está disponible.

## Problemas Críticos

1. **Health Check 100% fallido:** Servicio no responde al chequeo de salud
2. **Todas las operaciones CRUD fallan:** POST y GET list retornan 404
3. **Solo funciona búsqueda por ID:** GET individual funciona, pero es inconsistente
4. **Latencia extrema en P99:** 130ms es inaceptable
5. **Tasa de error insostenible:** 80% de fallos hace el servicio no confiable

---

# Análisis de Pruebas de Rendimiento - Product Service

## Resumen General
- **Total de Solicitudes:** 73
- **Solicitudes Fallidas:** 47 (64.38%)
- **Duración:** 30 segundos
- **Usuarios Concurrentes:** 5

---

## Métricas Clave

### Tiempo de Respuesta
- **Promedio:** 8 ms
- **Mínimo:** 3 ms
- **Máximo:** 82 ms
- **Mediana (P50):** 5 ms
- **P95:** 36 ms
- **P99:** 82 ms

Variabilidad extrema: P99 de 82ms indica problemas graves de consistencia bajo carga.

### Throughput
- **Requests por Segundo:** 2.53 req/s
- **Tasa de Errores por Segundo:** 1.63 errores/s

Throughput bajo para carga mínima (5 usuarios).

### Análisis por Endpoint

| Endpoint | Total Req | Fallos | Tasa Error | Tiempo Avg |
|----------|-----------|--------|-----------|-----------|
| GET /health | 6 | 6 | 100% | 5 ms |
| GET /products/{id} | 24 | 0 | 0% | 15 ms |
| GET /products?page=* | 28 | 28 | 100% | 12 ms |
| GET /products/search | 16 | 16 | 100% | 7 ms |

## Problemas Identificados

1. **Health Check fallando 100%:** Servicio reporta mala salud constantemente
2. **Búsquedas paginadas: 100% de fallos:** Todas las consultas con page parameter fallan
3. **Búsquedas por nombre: 100% de fallos:** Endpoint de búsqueda no funciona
4. **GETs por ID estables:** Solo funcionan búsquedas de productos por ID específico
5. **Latencia P99 crítica:** 82ms es inaceptable para operaciones READ

## Patrones de Fallo

- **Endpoints que funcionan:** GET /products/{id}
- **Endpoints rotos:** Cualquier operación que incluya paginación o búsqueda por texto
- **Health check:** Siempre retorna error (100% de fallos)

---

# Análisis de Pruebas de Rendimiento - Order Service

## Resumen General
- **Total de Solicitudes:** 72
- **Solicitudes Fallidas:** 36 (50.00%)
- **Duración:** 30 segundos
- **Usuarios Concurrentes:** 5

---

## Métricas Clave

### Tiempo de Respuesta
- **Promedio:** 10 ms
- **Mínimo:** 3 ms
- **Máximo:** 224 ms
- **Mediana (P50):** 5 ms
- **P95:** 19 ms
- **P99:** 220 ms

Variabilidad extrema: P99 de 220ms es inaceptable. Health check dispara latencias de hasta 224ms.

### Throughput
- **Requests por Segundo:** 2.45 req/s
- **Tasa de Errores por Segundo:** 1.23 errores/s

Throughput bajo considerando solo 5 usuarios.

### Análisis por Endpoint

| Endpoint | Total Req | Fallos | Tasa Error | Tiempo Avg |
|----------|-----------|--------|-----------|-----------|
| GET /health | 9 | 9 | 100% | 29 ms |
| GET /orders/{id} | 17 | 0 | 0% | 12 ms |
| GET /orders/user/{id} | 32 | 0 | 0% | 6 ms |
| GET /orders?page=* | 37 | 27 | 100% | 8 ms |

## Problemas Identificados

1. **Health Check fallando 100%:** Causa latencias extremas (máx 224ms)
2. **Paginación completamente rota:** 100% de fallos en todas las búsquedas paginadas
3. **GETs por ID y usuario funcionan:** Solo estos dos patrones tienen éxito (0% error)
4. **Latencia crítica en P99:** 220ms en health check genera timeouts
5. **Patrones inconsistentes:** GETs específicos funcionan, búsquedas generales fallan

## Problemas Críticos

**Endpoints que funcionan:**
- GET /orders/{id} - OK (0% error)
- GET /orders/user/{id} - OK (0% error)

**Endpoints rotos:**
- GET /actuator/health - 100% error, latencia 224ms máximo
- GET /orders?page=* - 100% error en paginación

---

# Pruebas Unitarias e Integración

## Resumen

**Pruebas Unitarias:** 5/6 servicios PASARON (83.33%)  
**Pruebas de Integración:** 5/6 servicios PASARON (83.33%)  
**Servicio No Implementado:** Favourite Service (pruebas no configuradas)

---

## Resultados por Tipo de Prueba

### Pruebas Unitarias

| Servicio | Estado | Resultado |
|----------|--------|-----------|
| Favourite Service | ⚠️ NO IMPLEMENTADO | BUILD FAILURE (sin pruebas) |
| Order Service | ✅ PASO | BUILD SUCCESS |
| Payment Service | ✅ PASO | BUILD SUCCESS |
| Product Service | ✅ PASO | BUILD SUCCESS |
| Shipping Service | ✅ PASO | BUILD SUCCESS |
| User Service | ✅ PASO | BUILD SUCCESS |

**Tasa de Éxito:** 83.33% (5/6) | **Servicios Implementados:** 5/6

### Pruebas de Integración

| Servicio | Estado | Resultado |
|----------|--------|-----------|
| Favourite Service | ⚠️ NO IMPLEMENTADO | BUILD FAILURE (sin pruebas) |
| Order Service | ✅ PASO | BUILD SUCCESS |
| Payment Service | ✅ PASO | BUILD SUCCESS |
| Product Service | ✅ PASO | BUILD SUCCESS |
| Shipping Service | ✅ PASO | BUILD SUCCESS |
| User Service | ✅ PASO | BUILD SUCCESS |

**Tasa de Éxito:** 83.33% (5/6) | **Servicios Implementados:** 5/6

---

## Aclaración Importante

### Favourite Service - Pruebas No Implementadas

El fallo de Favourite Service **no indica un problema de código**, sino que **las pruebas unitarias e integración no fueron implementadas** para este servicio.


---

## Análisis Crítico

### Servicios Listos (5/6)

**Order, Payment, Product, Shipping, User:**
- Código compila correctamente
- Tests unitarios implementados y pasando
- Tests de integración implementados y pasando
- Validación de dependencias externa funciona

### Servicio Pendiente (1/6)

**Favourite Service:**
- Código existe pero sin suite de pruebas
- Necesita desarrollo de tests unitarios
- Necesita desarrollo de tests integración
- Requiere validación pre-deployment

---
