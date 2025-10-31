# Checklist de Verificación - Stage Environment

Use esta checklist para verificar que todo está configurado correctamente.

## ✅ Pre-requisitos

- [ ] Kubernetes cluster accesible
- [ ] kubectl instalado y configurado
- [ ] Docker Hub credentials (usuario y token)
- [ ] Acceso de lectura/escritura a Kubernetes

## ✅ Fase 1: Configuración del Namespace

### Crear Namespace
```bash
kubectl create namespace stage
```
- [ ] Namespace 'stage' creado exitosamente
- [ ] Verificar: `kubectl get namespace stage`

### Crear Docker Registry Secret
```bash
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=TU_USUARIO \
  --docker-password=TU_TOKEN \
  --docker-email=TU_EMAIL \
  --namespace=stage
```
- [ ] Secret creado exitosamente
- [ ] Verificar: `kubectl get secrets -n stage | grep dockerhub`
- [ ] Detalles correctos: `kubectl describe secret dockerhub-credentials -n stage`

## ✅ Fase 2: Config Server

### Desplegar Config Server
```bash
kubectl apply -f config-server/configmap.yaml
kubectl apply -f config-server/service.yaml
kubectl apply -f config-server/deployment.yaml
```

### Verificar Config Server
- [ ] ConfigMap creado: `kubectl get configmap -n stage config-server-repo`
- [ ] Service creado: `kubectl get svc -n stage config-server`
- [ ] Deployment creado: `kubectl get deployment -n stage config-server`
- [ ] Pod en Running:
  ```bash
  kubectl get pods -n stage -l app=config-server
  # Debería mostrar: config-server-xxxxx    1/1 Running
  ```
- [ ] Logs sin errores:
  ```bash
  kubectl logs -n stage -l app=config-server | tail -20
  ```
- [ ] Health check responde:
  ```bash
  kubectl port-forward -n stage svc/config-server 8888:8888
  # En otra terminal: curl http://localhost:8888/actuator/health
  ```

## ✅ Fase 3: Zipkin

### Desplegar Zipkin
```bash
kubectl apply -f zipkin/service.yaml
kubectl apply -f zipkin/deployment.yaml
```

### Verificar Zipkin
- [ ] Service creado: `kubectl get svc -n stage zipkin`
- [ ] Deployment creado: `kubectl get deployment -n stage zipkin`
- [ ] Pod en Running:
  ```bash
  kubectl get pods -n stage -l app=zipkin
  # Debería mostrar: zipkin-xxxxx    1/1 Running
  ```
- [ ] Logs sin errores:
  ```bash
  kubectl logs -n stage -l app=zipkin | tail -20
  ```
- [ ] UI accesible:
  ```bash
  kubectl port-forward -n stage svc/zipkin 9411:9411
  # Acceder a: http://localhost:9411
  ```

## ✅ Fase 4: Service Discovery (Eureka)

### Desplegar Service Discovery
```bash
kubectl apply -f service-discovery/
```

### Verificar Service Discovery
- [ ] Service creado: `kubectl get svc -n stage service-discovery`
- [ ] Deployment creado: `kubectl get deployment -n stage service-discovery`
- [ ] Pod en Running:
  ```bash
  kubectl get pods -n stage -l app=service-discovery
  # Debería mostrar: service-discovery-xxxxx    1/1 Running
  ```
- [ ] Logs sin errores:
  ```bash
  kubectl logs -n stage -l app=service-discovery | tail -20
  ```
- [ ] UI accesible en puerto 8761

## ✅ Fase 5: Proxy Client

### Desplegar Proxy Client
```bash
kubectl apply -f proxy-client/
```

### Verificar Proxy Client
- [ ] Service creado: `kubectl get svc -n stage proxy-client`
- [ ] Deployment creado: `kubectl get deployment -n stage proxy-client`
- [ ] Pod en Running:
  ```bash
  kubectl get pods -n stage -l app=proxy-client
  # Debería mostrar: proxy-client-xxxxx    1/1 Running
  ```
- [ ] Logs sin errores:
  ```bash
  kubectl logs -n stage -l app=proxy-client | tail -20
  ```

## ✅ Fase 6: Microservicios

### Desplegar User Service
```bash
kubectl apply -f user-service/
```
- [ ] Service creado: `kubectl get svc -n stage user-service`
- [ ] Deployment creado: `kubectl get deployment -n stage user-service`
- [ ] Pod en Running (después de ~60 segundos):
  ```bash
  kubectl get pods -n stage -l app=user-service
  # Debería mostrar: user-service-xxxxx    1/1 Running
  ```
- [ ] Logs muestran startup exitoso
- [ ] Registrado con Eureka: Verificar en Eureka dashboard

### Desplegar Product Service
```bash
kubectl apply -f product-service/
```
- [ ] Pod en Running
- [ ] Logs sin errores
- [ ] Registrado con Eureka

### Desplegar Order Service
```bash
kubectl apply -f order-service/
```
- [ ] Pod en Running
- [ ] Logs sin errores
- [ ] Registrado con Eureka

### Desplegar Payment Service
```bash
kubectl apply -f payment-service/
```
- [ ] Pod en Running
- [ ] Logs sin errores
- [ ] Registrado con Eureka

### Desplegar Favourite Service
```bash
kubectl apply -f favourite-service/
```
- [ ] Pod en Running
- [ ] Logs sin errores
- [ ] Registrado con Eureka

### Desplegar Shipping Service
```bash
kubectl apply -f shipping-service/
```
- [ ] Pod en Running
- [ ] Logs sin errores
- [ ] Registrado con Eureka

## ✅ Fase 7: Verificación General

### Estado Global
```bash
kubectl get all -n stage
```
- [ ] 8 servicios (user, product, order, payment, favourite, shipping, proxy-client, config-server, zipkin, service-discovery)
- [ ] 8 deployments
- [ ] Todos los pods en estado Running
- [ ] Todos los pods con 1/1 Ready

### Recursos
```bash
kubectl top pods -n stage
kubectl top nodes
```
- [ ] Uso de memoria razonable
- [ ] CPU usage normal (sin picos)
- [ ] Suficientes recursos disponibles

### ConfigMaps
```bash
kubectl get configmap -n stage
```
- [ ] config-server-repo
- [ ] user-service-config
- [ ] product-service-config
- [ ] order-service-config
- [ ] payment-service-config
- [ ] favourite-service-config
- [ ] shipping-service-config
- [ ] proxy-client-config
- [ ] service-discovery-config

### Secrets
```bash
kubectl get secrets -n stage
```
- [ ] dockerhub-credentials presente
- [ ] Tipo correcto: kubernetes.io/dockercfg

## ✅ Fase 8: Conectividad

### Verificar DNS
```bash
# Ejecutar desde un pod
kubectl exec -it -n stage pod/user-service-xxxxx -- sh

# Dentro del pod:
nslookup config-server
nslookup zipkin
nslookup service-discovery
nslookup user-service

# Debería resolver correctamente a ClusterIP
```
- [ ] Todos los hosts resuelven correctamente

### Verificar Conectividad de Red
```bash
# Desde user-service a config-server
kubectl exec -it -n stage pod/user-service-xxxxx -- curl http://config-server:8888/actuator/health

# Desde user-service a zipkin
kubectl exec -it -n stage pod/user-service-xxxxx -- curl http://zipkin:9411/health

# Debería retornar 200 OK
```
- [ ] user-service → config-server: OK
- [ ] user-service → zipkin: OK
- [ ] user-service → service-discovery: OK

## ✅ Fase 9: Health Checks

### Verificar Liveness Probes
```bash
kubectl get pods -n stage -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```
- [ ] Todos los pods muestran "True"

### Verificar Readiness Probes
```bash
kubectl describe pods -n stage -l app=user-service | grep -A 10 "Readiness"
```
- [ ] Readiness gates mostran success
- [ ] Todos los pods marcados como Ready

## ✅ Fase 10: Acceso a Servicios

### Port-Forward Config Server
```bash
kubectl port-forward -n stage svc/config-server 8888:8888 &
curl http://localhost:8888/actuator/health
```
- [ ] Responde con health status

### Port-Forward Zipkin
```bash
kubectl port-forward -n stage svc/zipkin 9411:9411 &
# Acceder a http://localhost:9411
```
- [ ] Zipkin UI carga correctamente
- [ ] Dashboard es accesible

### Port-Forward User Service
```bash
kubectl port-forward -n stage svc/user-service 8700:8700 &
curl http://localhost:8700/actuator/health
```
- [ ] Health endpoint responde
- [ ] Otros endpoints funcionan

### Port-Forward Proxy Client
```bash
kubectl port-forward -n stage svc/proxy-client 8200:8200 &
```
- [ ] Proxy Client es accesible
- [ ] Enruta requests correctamente

## ✅ Fase 11: Integración

### Verificar Service Discovery Registration
```bash
kubectl port-forward -n stage svc/service-discovery 8761:8761
# Acceder a http://localhost:8761
```
- [ ] user-service registrado
- [ ] product-service registrado
- [ ] order-service registrado
- [ ] payment-service registrado
- [ ] favourite-service registrado
- [ ] shipping-service registrado
- [ ] proxy-client registrado

### Verificar Inter-Service Communication
```bash
# Ejecutar desde user-service
kubectl exec -it -n stage pod/user-service-xxxxx -- sh

# Dentro del pod:
curl http://product-service:8500/actuator/health
curl http://order-service:8300/actuator/health
curl http://payment-service:8400/actuator/health
```
- [ ] user-service → product-service: OK
- [ ] user-service → order-service: OK
- [ ] user-service → payment-service: OK
- [ ] user-service → favourite-service: OK
- [ ] user-service → shipping-service: OK

## ✅ Fase 12: Logs y Eventos

### Verificar Logs
```bash
kubectl logs -n stage -l app=user-service --tail=50
kubectl logs -n stage -l app=config-server --tail=50
```
- [ ] Sin errores críticos
- [ ] Servicios inicializados correctamente
- [ ] Conectividad establecida

### Verificar Eventos
```bash
kubectl get events -n stage --sort-by='.lastTimestamp' | tail -30
```
- [ ] Sin errores de ImagePull
- [ ] Sin errores de mounting
- [ ] Eventos normales de creación

## ✅ Fase 13: Performance

### Métricas de CPU/Memoria
```bash
kubectl top pods -n stage
kubectl top nodes
```
- [ ] Uso de memoria < 70%
- [ ] Uso de CPU < 70%
- [ ] Nodos con suficientes recursos

### Verificar Restart Counts
```bash
kubectl get pods -n stage -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'
```
- [ ] Todos los restarts = 0
- [ ] Sin CrashLoopBackOff

## ✅ Fase 14: Datos Persistentes

### Verificar ConfigMaps
```bash
kubectl get configmap -n stage config-server-repo -o yaml | head -50
```
- [ ] Configuración de servicios presente
- [ ] YAML válido

## 📋 Resumen Final

### Total de Verificaciones
- [ ] Pre-requisitos: 3/3
- [ ] Namespace: 2/2
- [ ] Config Server: 5/5
- [ ] Zipkin: 5/5
- [ ] Service Discovery: 5/5
- [ ] Proxy Client: 4/4
- [ ] Microservicios: 30/30
- [ ] Verificación General: 4/4
- [ ] Recursos: 2/2
- [ ] ConfigMaps: 9/9
- [ ] Secrets: 2/2
- [ ] Conectividad: 2/2
- [ ] Health Checks: 2/2
- [ ] Acceso: 4/4
- [ ] Integración: 2/2
- [ ] Logs/Eventos: 2/2
- [ ] Performance: 3/3
- [ ] Datos: 1/1

**Total: 97 verificaciones**

## ✨ Estado Final

- [ ] Todas las verificaciones completadas
- [ ] Ambiente stage 100% operacional
- [ ] Listo para pruebas de integración
- [ ] Listo para despliegue de cambios

## 🎯 Siguientes Pasos

Una vez todo verificado:
1. [ ] Ejecutar pruebas unitarias
2. [ ] Ejecutar pruebas de integración
3. [ ] Ejecutar pruebas E2E
4. [ ] Ejecutar pruebas de carga
5. [ ] Revisar reportes y métricas
6. [ ] Aprobar para stage
7. [ ] Preparar para producción

---

**Fecha de verificación**: _______________
**Verificado por**: _______________
**Estado**: ⬜ En progreso / ✅ Completado / ❌ Fallido
