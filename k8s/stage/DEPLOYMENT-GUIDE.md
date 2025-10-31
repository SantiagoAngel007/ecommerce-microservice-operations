# Guía de Despliegue - Stage Environment

Esta guía te lleva a través del proceso completo de despliegue de todos los servicios en el ambiente stage.

## 1. Configuración Inicial del Namespace

### Paso 1a: Con Script Automático (Recomendado)

**En Windows PowerShell:**
```powershell
cd k8s/stage
.\setup-stage-namespace.ps1 -DockerUsername "tu_usuario" -DockerToken "tu_token" -DockerEmail "tu_email@example.com"
```

**En Linux/macOS:**
```bash
cd k8s/stage
chmod +x setup-stage-namespace.sh
./setup-stage-namespace.sh tu_usuario tu_token tu_email@example.com
```

### Paso 1b: Manual

```bash
# 1. Crear namespace
kubectl create namespace stage

# 2. Crear Docker Registry Secret
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=tu_usuario \
  --docker-password=tu_token \
  --docker-email=tu_email@example.com \
  --namespace=stage

# 3. Desplegar Config Server
kubectl apply -f config-server/

# 4. Desplegar Zipkin
kubectl apply -f zipkin/
```

**Espera a que estén listos:**
```bash
kubectl wait --for=condition=available --timeout=300s deployment/config-server -n stage
kubectl wait --for=condition=available --timeout=300s deployment/zipkin -n stage
```

## 2. Verificar que Infraestructura Está Lista

```bash
# Verificar pods
kubectl get pods -n stage

# Debería mostrar:
# - config-server-xxxxx  (1/1 Running)
# - zipkin-xxxxx         (1/1 Running)
# - service-discovery-xxxxx (1/1 Running)
# - proxy-client-xxxxx   (1/1 Running)
```

## 3. Desplegar Service Discovery (Eureka)

```bash
kubectl apply -f service-discovery/

# Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s deployment/service-discovery -n stage
```

## 4. Desplegar Proxy Client

```bash
kubectl apply -f proxy-client/

# Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s deployment/proxy-client -n stage
```

## 5. Desplegar Microservicios

### Opción A: Desplegar todos de una vez
```bash
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f favourite-service/
kubectl apply -f shipping-service/
```

### Opción B: Desplegar selectivamente
```bash
# Solo los servicios que necesites
kubectl apply -f user-service/
kubectl apply -f product-service/
```

### Verificar despliegue
```bash
# Ver todos los pods
kubectl get pods -n stage

# Ver deployments
kubectl get deployments -n stage

# Ver servicios
kubectl get services -n stage
```

## 6. Esperar a que Todo Esté Listo

```bash
# Esperar a que todos los deployments estén disponibles
kubectl wait --for=condition=available --timeout=600s deployment -n stage --all

# Verificar status
kubectl get all -n stage
```

## 7. Acceder a los Servicios

### Opción A: Port-Forward (Desarrollo Local)

```bash
# En una terminal separada para cada servicio:

# Proxy Client
kubectl port-forward -n stage svc/proxy-client 8200:8200

# User Service
kubectl port-forward -n stage svc/user-service 8700:8700

# Zipkin
kubectl port-forward -n stage svc/zipkin 9411:9411

# Config Server
kubectl port-forward -n stage svc/config-server 8888:8888
```

**Luego accede a:**
- Proxy Client: http://localhost:8200
- Zipkin: http://localhost:9411
- Config Server: http://localhost:8888

### Opción B: Obtener ClusterIP (Acceso dentro del cluster)

```bash
kubectl get svc -n stage

# Ejemplo output:
# NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
# proxy-client        ClusterIP   10.0.0.10      <none>        8200/TCP
# zipkin              ClusterIP   10.0.0.11      <none>        9411/TCP
# config-server       ClusterIP   10.0.0.12      <none>        8888/TCP
```

## Verificación por Pasos

### Paso 1: Verificar que el namespace existe
```bash
kubectl get namespace stage
```

### Paso 2: Verificar secrets
```bash
kubectl get secrets -n stage
# Debería mostrar: dockerhub-credentials
```

### Paso 3: Verificar ConfigMaps
```bash
kubectl get configmap -n stage
# Debería mostrar: config-server-repo, service-discovery-config, etc.
```

### Paso 4: Verificar servicios de infraestructura
```bash
kubectl get svc -n stage -l "app in (config-server, zipkin, service-discovery)"
```

### Paso 5: Verificar deployments
```bash
kubectl get deployments -n stage
kubectl describe deployment user-service -n stage
```

### Paso 6: Verificar logs
```bash
# Config Server
kubectl logs -n stage -l app=config-server

# Zipkin
kubectl logs -n stage -l app=zipkin

# User Service
kubectl logs -n stage -l app=user-service

# Ver logs en tiempo real
kubectl logs -f -n stage -l app=user-service
```

### Paso 7: Verificar conectividad
```bash
# Ejecutar comando en un pod
kubectl exec -it -n stage pod/user-service-xxxxx -- sh

# Dentro del pod:
# Probar conectividad a Zipkin
curl http://zipkin:9411/health

# Probar conectividad a Config Server
curl http://config-server:8888/application/stage

# Salir del pod
exit
```

## Health Checks

### Verificar salud de servicios
```bash
# User Service
curl http://localhost:8700/actuator/health

# Zipkin
curl http://localhost:9411/health

# Config Server
curl http://localhost:8888/actuator/health
```

## Scaling (Aumentar replicas)

```bash
# Escalar user-service a 3 replicas
kubectl scale deployment user-service -n stage --replicas=3

# Verificar
kubectl get pods -n stage -l app=user-service
```

## Actualizar Servicios

### Actualizar imagen
```bash
kubectl set image deployment/user-service \
  user-service=merako34/user-service:0.2.0 \
  -n stage
```

### Actualizar ConfigMap
```bash
# Editar en vivo
kubectl edit configmap user-service-config -n stage

# O aplicar nuevo archivo
kubectl apply -f user-service/configmap.yaml
```

## Limpieza

### Eliminar un servicio
```bash
kubectl delete -f user-service/ -n stage
```

### Eliminar todos los servicios
```bash
kubectl delete all -n stage
```

### Eliminar el namespace completo
```bash
kubectl delete namespace stage
```

## Troubleshooting

### ImagePullBackOff
```bash
# Verificar que el secret existe y es correcto
kubectl get secret dockerhub-credentials -n stage -o yaml

# Recrear el secret si es necesario
kubectl delete secret dockerhub-credentials -n stage
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=tu_usuario \
  --docker-password=tu_token \
  --docker-email=tu_email@example.com \
  --namespace=stage
```

### Pods no inician
```bash
# Ver descripción del pod
kubectl describe pod -n stage pod/user-service-xxxxx

# Ver logs
kubectl logs -n stage pod/user-service-xxxxx

# Ver eventos
kubectl get events -n stage --sort-by='.lastTimestamp'
```

### Config Server no responde
```bash
# Verificar que Config Server está corriendo
kubectl get pods -n stage -l app=config-server

# Ver logs
kubectl logs -n stage -l app=config-server

# Probar conectividad
kubectl exec -it -n stage pod/user-service-xxxxx -- curl http://config-server:8888/health
```

### Zipkin no recibe traces
```bash
# Verificar que Zipkin está corriendo
kubectl get pods -n stage -l app=zipkin

# Ver logs
kubectl logs -n stage -l app=zipkin

# Verificar puerto
kubectl get svc -n stage zipkin
```

## Monitoreo

### Ver recursos en tiempo real
```bash
# Recursos de pods
kubectl top pods -n stage

# Recursos de nodos
kubectl top nodes
```

### Ver eventos
```bash
kubectl get events -n stage --sort-by='.lastTimestamp' --watch
```

### Estadísticas detalladas
```bash
kubectl describe nodes
kubectl describe pod -n stage pod/user-service-xxxxx
```

## Rollback

### Si necesitas revertir a una versión anterior
```bash
# Ver historial de rollouts
kubectl rollout history deployment/user-service -n stage

# Revertir al deployment anterior
kubectl rollout undo deployment/user-service -n stage

# Revertir a una revisión específica
kubectl rollout undo deployment/user-service -n stage --to-revision=2
```

## Notas Importantes

1. **Base de datos en memoria**: Los datos se pierden al reiniciar los pods. Para producción, usa una BD persistente.

2. **Secrets**: Cambia las credenciales por defecto en production.

3. **Recursos**: Ajusta requests y limits según tu cluster.

4. **Network Policies**: Considera agregar network policies en producción.

5. **RBAC**: Configura RBAC para limitar permisos.

## Duración Estimada

- Setup automático: 5-10 minutos
- Setup manual: 15-20 minutos
- Despliegue de todos los servicios: 10-15 minutos
- Total: 20-45 minutos

## Siguiente Paso

Una vez desplegado, puedes:
1. Acceder a la API a través del Proxy Client: http://localhost:8200
2. Ver traces en Zipkin: http://localhost:9411
3. Ver configuración en Config Server: http://localhost:8888
4. Ejecutar pruebas de integración
5. Monitorear logs y métricas
