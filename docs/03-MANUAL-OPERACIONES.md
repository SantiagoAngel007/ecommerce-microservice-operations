# 🛠️ Manual de Operaciones

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Audiencia:** DevOps, SREs, Desarrolladores

---

## 📋 Tabla de Contenidos

1. [Operaciones Diarias](#operaciones-diarias)
2. [Monitoreo y Alertas](#monitoreo-y-alertas)
3. [Gestión de Logs](#gestión-de-logs)
4. [Escalamiento](#escalamiento)
5. [Despliegues](#despliegues)
6. [Rollbacks](#rollbacks)
7. [Troubleshooting](#troubleshooting)
8. [Mantenimiento](#mantenimiento)
9. [Gestión de Incidentes](#gestión-de-incidentes)
10. [Comandos de Referencia Rápida](#comandos-de-referencia-rápida)

---

## 📅 Operaciones Diarias

### Checklist Matutino (9:00 AM)

#### 1. Verificar Estado del Cluster

**📸 Screenshot 33:**
```bash
# Verificar estado de nodos
kubectl get nodes
kubectl top nodes

# Verificar estado de todos los pods
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod

# Resumen de recursos
kubectl top pods -n dev --sort-by=cpu
kubectl top pods -n dev --sort-by=memory
```
> **Archivo:** `screenshots/33-daily-cluster-health.png`  
> **Descripción:** Estado diario del cluster y recursos

#### 2. Revisar Health de Servicios

**📸 Screenshot 34:**
```bash
# Script de health check
cat > ~/check-health.sh << 'EOF'
#!/bin/bash
NAMESPACE=${1:-dev}
echo "=== Health Check: $NAMESPACE ==="

SERVICES=(
  "service-discovery:8761"
  "config-server:8888"
  "api-gateway:8200"
  "user-service:8700"
  "product-service:8500"
  "order-service:8300"
  "payment-service:8400"
  "shipping-service:8600"
  "favourite-service:8800"
)

for svc in "${SERVICES[@]}"; do
  name=$(echo $svc | cut -d: -f1)
  port=$(echo $svc | cut -d: -f2)
  
  echo -n "Checking $name... "
  
  status=$(kubectl exec -n $NAMESPACE deploy/$name -- \
    curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:$port/actuator/health 2>/dev/null)
  
  if [ "$status" = "200" ]; then
    echo "✅ OK"
  else
    echo "❌ FAIL (HTTP $status)"
  fi
done
EOF

chmod +x ~/check-health.sh
~/check-health.sh dev
```
> **Archivo:** `screenshots/34-services-health-check.png`

#### 3. Revisar Logs de Errores

```bash
# Errores en las últimas 24h
kubectl logs -n dev --since=24h --all-containers \
  --selector='tier=backend' | grep -i error | tail -50

# Logs de crashloop
kubectl get pods -n dev | grep -E 'CrashLoop|Error' | \
  awk '{print $1}' | xargs -I {} kubectl logs -n dev {} --tail=100
```

#### 4. Verificar Métricas de Negocio

```bash
# Órdenes creadas en las últimas 24h
kubectl exec -n dev deploy/order-service -- \
  curl -s http://localhost:8300/actuator/metrics/orders.created | jq

# Usuarios activos
kubectl exec -n dev deploy/user-service -- \
  curl -s http://localhost:8700/actuator/metrics/users.active | jq

# Tasa de error en pagos
kubectl exec -n dev deploy/payment-service -- \
  curl -s http://localhost:8400/actuator/metrics/payments.error.rate | jq
```

#### 5. Revisar Pipelines CI/CD

**📸 Screenshot 35:**
```bash
# Ver últimos builds en Jenkins
# Acceder a: http://<JENKINS-IP>:8080

# O via API
curl -s -u admin:$JENKINS_TOKEN \
  "$JENKINS_URL/api/json?tree=jobs[name,lastBuild[number,result,timestamp]]" | \
  jq -r '.jobs[] | "\(.name): \(.lastBuild.result) (#\(.lastBuild.number))"'
```
> **Archivo:** `screenshots/35-jenkins-recent-builds.png`

### Checklist Vespertino (5:00 PM)

```bash
# 1. Revisar consumo de recursos del día
kubectl top nodes
kubectl top pods -n dev --sort-by=memory

# 2. Revisar logs de Zipkin para traces lentos
# Abrir: http://<ZIPKIN-IP>:9411
# Buscar traces > 1000ms

# 3. Verificar respaldos
gsutil ls gs://$BACKUP_BUCKET/$(date +%Y-%m-%d)/

# 4. Documentar incidentes del día
echo "$(date): [INCIDENT_SUMMARY]" >> ~/incident-log.txt
```

---

## 📊 Monitoreo y Alertas

### Dashboards Principales

#### 1. Eureka Dashboard

**URL:** `http://<SERVICE-DISCOVERY-IP>:8761`

**Verificaciones:**
- ✅ Todos los servicios registrados (9 instancias mínimo)
- ✅ Estado: UP para todos
- ✅ Último heartbeat < 30 segundos

**📸 Screenshot 36:**
```bash
# Obtener estado via API
curl -s http://<SERVICE-DISCOVERY-IP>:8761/eureka/apps | \
  grep -o '<app>[^<]*</app>' | sed 's/<[^>]*>//g' | sort | uniq -c
```
> **Archivo:** `screenshots/36-eureka-services-registered.png`

#### 2. Zipkin Tracing

**URL:** `http://<ZIPKIN-IP>:9411`

**Métricas clave:**
- Latencia promedio por servicio
- Tasa de errores en traces
- Servicios más lentos

**📸 Screenshot 37:**
```bash
# Traces recientes con errores
curl -s "http://<ZIPKIN-IP>:9411/api/v2/traces?annotationQuery=error" | \
  jq -r '.[] | .[] | select(.tags.error) | 
    "\(.name) - \(.tags."http.status_code") - \(.duration/1000)ms"' | head -20
```
> **Archivo:** `screenshots/37-zipkin-error-traces.png`

#### 3. Actuator Metrics

**📸 Screenshot 38:**
```bash
# Script para recolectar métricas de todos los servicios
cat > ~/collect-metrics.sh << 'EOF'
#!/bin/bash
NAMESPACE=${1:-dev}
SERVICES=(service-discovery config-server api-gateway user-service 
          product-service order-service payment-service shipping-service 
          favourite-service)

for svc in "${SERVICES[@]}"; do
  echo "=== $svc ==="
  
  # CPU y memoria
  kubectl exec -n $NAMESPACE deploy/$svc -- \
    curl -s http://localhost:8761/actuator/metrics/process.cpu.usage | \
    jq -r '.measurements[0].value'
  
  # JVM memory
  kubectl exec -n $NAMESPACE deploy/$svc -- \
    curl -s http://localhost:8761/actuator/metrics/jvm.memory.used | \
    jq -r '.measurements[0].value / 1024 / 1024 | "\(.)MB"'
  
  # HTTP requests
  kubectl exec -n $NAMESPACE deploy/$svc -- \
    curl -s http://localhost:8761/actuator/metrics/http.server.requests | \
    jq -r '.measurements[] | "\(.statistic): \(.value)"'
  
  echo ""
done
EOF

chmod +x ~/collect-metrics.sh
~/collect-metrics.sh dev
```
> **Archivo:** `screenshots/38-actuator-metrics-summary.png`

### Configurar Alertas

#### Prometheus + AlertManager (si está configurado)

```yaml
# prometheus-alerts.yaml
groups:
  - name: microservices
    interval: 30s
    rules:
      # Pod down
      - alert: PodDown
        expr: up{job="kubernetes-pods"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is down"
          description: "Pod has been down for more than 5 minutes"
      
      # High memory usage
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.pod }}"
          description: "Memory usage is above 90%"
      
      # High CPU usage
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.pod }}"
      
      # High error rate
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.service }}"
```

**Aplicar:**
```bash
kubectl apply -f prometheus-alerts.yaml -n monitoring
```

#### GCP Monitoring (Stackdriver)

**📸 Screenshot 39:**
```bash
# Crear alerta de presupuesto via gcloud
gcloud billing budgets create \
  --billing-account=$BILLING_ACCOUNT_ID \
  --display-name="E-Commerce Monthly Budget Alert" \
  --budget-amount=100USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100

# Crear alerta de uptime
gcloud monitoring uptime-check-configs create http-uptime-check \
  --display-name="API Gateway Uptime" \
  --resource-type=uptime-url \
  --monitored-resource=host=<API-GATEWAY-IP>,port=8200 \
  --http-check-path=/actuator/health
```
> **Archivo:** `screenshots/39-gcp-monitoring-alerts.png`

---

## 📝 Gestión de Logs

### Logs Centralizados

#### 1. Ver Logs en Tiempo Real

**📸 Screenshot 40:**
```bash
# Seguir logs de un servicio
kubectl logs -f -n dev deploy/order-service

# Seguir logs de todos los contenedores en un pod
kubectl logs -f -n dev <pod-name> --all-containers

# Logs de múltiples servicios
kubectl logs -f -n dev -l tier=backend

# Logs con timestamps
kubectl logs -n dev deploy/order-service --timestamps=true --since=1h
```
> **Archivo:** `screenshots/40-live-logs-streaming.png`

#### 2. Búsqueda de Errores

```bash
# Errores en las últimas 24 horas
kubectl logs -n dev --since=24h --all-containers=true -l tier=backend | \
  grep -i "error\|exception\|fatal" | \
  grep -v "No error" | \
  tail -100

# Errores agrupados por tipo
kubectl logs -n dev --since=1h --all-containers=true -l tier=backend | \
  grep -i "exception" | \
  sed 's/.*Exception: //' | \
  cut -d: -f1 | \
  sort | uniq -c | sort -rn

# Logs de un pod específico antes de crashear
kubectl logs -n dev <pod-name> --previous
```

#### 3. Exportar Logs para Análisis

```bash
# Exportar logs de las últimas 24h a archivo
kubectl logs -n dev --since=24h --all-containers=true \
  -l tier=backend > logs-$(date +%Y%m%d).txt

# Comprimir y subir a bucket
gzip logs-$(date +%Y%m%d).txt
gsutil cp logs-$(date +%Y%m%d).txt.gz \
  gs://$BACKUP_BUCKET/logs/$(date +%Y)/$(date +%m)/

# Logs de todos los pods en el namespace
for pod in $(kubectl get pods -n dev -o name); do
  kubectl logs -n dev $pod --all-containers=true > "${pod//\//-}.log"
done
tar -czf logs-dev-$(date +%Y%m%d).tar.gz *.log
rm *.log
```

### Análisis de Logs con Cloud Logging

**📸 Screenshot 41:**
```bash
# Query en Cloud Logging (GCP Console)
# Navigation menu → Logging → Logs Explorer

# Query ejemplo:
# resource.type="k8s_container"
# resource.labels.namespace_name="dev"
# severity="ERROR"
# timestamp>="2025-12-01T00:00:00Z"

# Via gcloud
gcloud logging read \
  'resource.type="k8s_container" AND 
   resource.labels.namespace_name="dev" AND 
   severity="ERROR"' \
  --limit=50 \
  --format=json
```
> **Archivo:** `screenshots/41-cloud-logging-errors.png`

---

## 📈 Escalamiento

### Auto-Scaling en GKE Autopilot

**GKE Autopilot escala automáticamente**, pero puedes monitorear:

**📸 Screenshot 42:**
```bash
# Ver HPA (Horizontal Pod Autoscaler) si está configurado
kubectl get hpa -n dev

# Ver estado de nodos
kubectl get nodes -o wide

# Ver eventos de escalamiento
kubectl get events -n dev --sort-by='.lastTimestamp' | grep -i scale
```
> **Archivo:** `screenshots/42-autoscaling-status.png`

### Escalamiento Manual de Pods

```bash
# Escalar un deployment
kubectl scale deployment order-service -n dev --replicas=5

# Verificar escalamiento
kubectl get deployment order-service -n dev
kubectl rollout status deployment/order-service -n dev

# Escalar múltiples servicios
SERVICES=(user-service product-service order-service payment-service)
for svc in "${SERVICES[@]}"; do
  kubectl scale deployment $svc -n dev --replicas=3
done

# Ver estado
kubectl get deployments -n dev
```

**📸 Screenshot 43:**
```bash
# Antes y después del escalamiento
kubectl get pods -n dev -l app=order-service -o wide
```
> **Archivo:** `screenshots/43-manual-scaling-result.png`

### Configurar HPA (Horizontal Pod Autoscaler)

```yaml
# order-service-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max
```

**Aplicar:**
```bash
kubectl apply -f order-service-hpa.yaml

# Monitorear HPA
kubectl get hpa -n dev -w

# Detalles del HPA
kubectl describe hpa order-service-hpa -n dev
```

### Escalamiento de Nodos (GKE Standard)

```bash
# Ver configuración actual del node pool
gcloud container node-pools describe default-pool \
  --cluster=ecommerce-dev-cluster \
  --region=us-central1

# Escalar manualmente (GKE Standard)
gcloud container clusters resize ecommerce-dev-cluster \
  --node-pool=default-pool \
  --num-nodes=5 \
  --region=us-central1

# Configurar autoscaling de nodos (GKE Standard)
gcloud container clusters update ecommerce-dev-cluster \
  --enable-autoscaling \
  --min-nodes=3 \
  --max-nodes=10 \
  --node-pool=default-pool \
  --region=us-central1
```

---

## 🚀 Despliegues

### Despliegue via Jenkins (Recomendado)

**📸 Screenshot 44:**
```bash
# Trigger manual desde CLI
curl -X POST \
  -u admin:$JENKINS_TOKEN \
  "$JENKINS_URL/job/ecommerce-dev-pipeline/build"

# Ver progreso
curl -s -u admin:$JENKINS_TOKEN \
  "$JENKINS_URL/job/ecommerce-dev-pipeline/lastBuild/api/json" | \
  jq -r '.result'

# Ver logs del build
curl -s -u admin:$JENKINS_TOKEN \
  "$JENKINS_URL/job/ecommerce-dev-pipeline/lastBuild/consoleText"
```
> **Archivo:** `screenshots/44-jenkins-manual-deployment.png`

### Despliegue Manual con kubectl

#### 1. Actualizar Imagen

```bash
# Opción 1: Edit deployment
kubectl set image deployment/order-service \
  order-service=us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-services/order-service:v1.2.0 \
  -n dev

# Opción 2: Patch deployment
kubectl patch deployment order-service -n dev \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"order-service","image":"us-central1-docker.pkg.dev/'$PROJECT_ID'/ecommerce-services/order-service:v1.2.0"}]}}}}'

# Verificar rollout
kubectl rollout status deployment/order-service -n dev
```

#### 2. Actualizar ConfigMap

```bash
# Editar ConfigMap
kubectl edit configmap order-service-config -n dev

# O aplicar archivo actualizado
kubectl apply -f k8s/dev/order-service/configmap.yaml

# Reiniciar pods para aplicar cambios
kubectl rollout restart deployment/order-service -n dev

# Verificar
kubectl rollout status deployment/order-service -n dev
```

#### 3. Despliegue Blue-Green

```yaml
# order-service-v2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-v2
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
      version: v2
  template:
    metadata:
      labels:
        app: order-service
        version: v2
    spec:
      containers:
      - name: order-service
        image: us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-services/order-service:v2.0.0
        # ... resto de la config
```

```bash
# 1. Desplegar v2 sin routing de tráfico
kubectl apply -f order-service-v2-deployment.yaml

# 2. Verificar v2
kubectl get pods -n dev -l version=v2
kubectl logs -n dev -l version=v2

# 3. Cambiar Service para apuntar a v2
kubectl patch service order-service -n dev \
  -p '{"spec":{"selector":{"version":"v2"}}}'

# 4. Verificar tráfico
curl http://<ORDER-SERVICE-IP>:8300/actuator/info

# 5. Si todo OK, eliminar v1
kubectl delete deployment order-service -n dev

# 6. Renombrar v2 a v1
kubectl patch deployment order-service-v2 -n dev \
  --type='json' -p='[{"op": "replace", "path": "/metadata/name", "value":"order-service"}]'
```

#### 4. Canary Deployment

```bash
# 1. Mantener v1 con 3 réplicas
kubectl scale deployment order-service -n dev --replicas=3

# 2. Desplegar v2 con 1 réplica (25% tráfico)
kubectl apply -f order-service-v2-deployment.yaml
kubectl scale deployment order-service-v2 -n dev --replicas=1

# 3. Monitorear métricas de v2
kubectl logs -n dev -l version=v2 -f

# 4. Si OK, incrementar v2 y decrementar v1
kubectl scale deployment order-service-v2 -n dev --replicas=2
kubectl scale deployment order-service -n dev --replicas=2

# 5. Eventualmente: 100% v2, 0% v1
kubectl scale deployment order-service-v2 -n dev --replicas=4
kubectl scale deployment order-service -n dev --replicas=0
kubectl delete deployment order-service -n dev
```

### Verificación Post-Despliegue

**📸 Screenshot 45:**
```bash
# 1. Verificar pods nuevos
kubectl get pods -n dev -l app=order-service -o wide

# 2. Verificar rollout completo
kubectl rollout history deployment/order-service -n dev
kubectl rollout status deployment/order-service -n dev

# 3. Health check
curl http://<ORDER-SERVICE-IP>:8300/actuator/health

# 4. Verificar registro en Eureka
curl http://<SERVICE-DISCOVERY-IP>:8761/eureka/apps/ORDER-SERVICE

# 5. Test funcional
curl -X POST http://<API-GATEWAY-IP>:8200/api/order-service/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"products":[{"productId":1,"quantity":2}]}'

# 6. Verificar trace en Zipkin
# http://<ZIPKIN-IP>:9411 → buscar último trace

# 7. Verificar logs
kubectl logs -n dev -l app=order-service --tail=50
```
> **Archivo:** `screenshots/45-post-deployment-verification.png`

---

## ⏪ Rollbacks

### Rollback Rápido

**📸 Screenshot 46:**
```bash
# Ver historial de deployments
kubectl rollout history deployment/order-service -n dev

# Rollback a versión anterior
kubectl rollout undo deployment/order-service -n dev

# Rollback a versión específica
kubectl rollout undo deployment/order-service -n dev --to-revision=3

# Verificar rollback
kubectl rollout status deployment/order-service -n dev
kubectl get pods -n dev -l app=order-service
```
> **Archivo:** `screenshots/46-rollback-execution.png`

### Rollback de ConfigMap

```bash
# Backup antes de cambiar
kubectl get configmap order-service-config -n dev -o yaml > \
  order-service-config-backup-$(date +%Y%m%d).yaml

# Restaurar desde backup
kubectl apply -f order-service-config-backup-20251201.yaml

# Reiniciar para aplicar
kubectl rollout restart deployment/order-service -n dev
```

### Rollback de Infraestructura (Terraform)

```bash
cd terraform/environments/dev

# Ver historial de state
terraform state list

# Ver cambios en último apply
terraform show

# Rollback a versión anterior del state
# 1. Listar versiones del state en GCS
gsutil ls -l gs://$TERRAFORM_STATE_BUCKET/dev/

# 2. Descargar versión anterior
gsutil cp gs://$TERRAFORM_STATE_BUCKET/dev/terraform.tfstate#<version> \
  terraform.tfstate.backup

# 3. Aplicar estado anterior
mv terraform.tfstate terraform.tfstate.new
mv terraform.tfstate.backup terraform.tfstate
terraform apply

# O usar Terraform Cloud/Enterprise con version control
```

---

## 🔧 Troubleshooting

### Problemas Comunes y Soluciones

#### 1. Pod en CrashLoopBackOff

**Diagnóstico:**
```bash
# Ver logs del pod
kubectl logs -n dev <pod-name> --previous

# Describir pod
kubectl describe pod -n dev <pod-name>

# Eventos recientes
kubectl get events -n dev --sort-by='.lastTimestamp' | grep <pod-name>
```

**Causas comunes:**
- ❌ Aplicación falla al iniciar (revisar logs)
- ❌ Health check falla (revisar liveness/readiness probe)
- ❌ Configuración incorrecta (verificar ConfigMap)
- ❌ Dependencias no disponibles (Eureka, base de datos)

**Soluciones:**
```bash
# Revisar ConfigMap
kubectl get configmap <service>-config -n dev -o yaml

# Verificar secretos
kubectl get secrets -n dev

# Verificar conectividad a dependencias
kubectl exec -it -n dev <pod-name> -- sh
# Dentro del pod:
curl http://service-discovery:8761/eureka/apps
ping postgres-service
```

#### 2. Service No Responde (503/504)

**Diagnóstico:**
```bash
# Verificar endpoints
kubectl get endpoints -n dev <service-name>

# Verificar Service
kubectl describe svc -n dev <service-name>

# Test de conectividad
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n dev -- \
  curl http://<service-name>:8300/actuator/health
```

**Soluciones:**
```bash
# Verificar selector del Service coincide con labels de pods
kubectl get svc <service-name> -n dev -o yaml | grep selector -A 5
kubectl get pods -n dev -l app=<service-name> --show-labels

# Verificar puertos
kubectl get svc <service-name> -n dev -o yaml | grep -A 10 "ports:"
```

#### 3. Alta Latencia

**Diagnóstico:**
```bash
# Ver traces lentos en Zipkin
# http://<ZIPKIN-IP>:9411 → buscar traces > 1000ms

# Métricas de latencia
kubectl exec -n dev deploy/<service> -- \
  curl -s http://localhost:8300/actuator/metrics/http.server.requests | \
  jq '.availableTags[] | select(.tag=="uri") | .values'

# Top pods por CPU
kubectl top pods -n dev --sort-by=cpu
```

**Soluciones:**
```bash
# Escalar pods
kubectl scale deployment <service> -n dev --replicas=5

# Optimizar JVM settings
kubectl set env deployment/<service> -n dev \
  JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

# Habilitar caching
kubectl edit configmap <service>-config -n dev
# Agregar: spring.cache.type=redis
```

#### 4. Memory Leak

**Diagnóstico:**
```bash
# Monitorear memoria en tiempo real
kubectl top pods -n dev -l app=<service> --watch

# Ver métricas JVM
kubectl exec -n dev deploy/<service> -- \
  curl -s http://localhost:8300/actuator/metrics/jvm.memory.used | jq

# Heap dump (si es necesario)
kubectl exec -n dev <pod-name> -- \
  jmap -dump:format=b,file=/tmp/heap.hprof 1
```

**Soluciones:**
```bash
# Aumentar límites temporalmente
kubectl set resources deployment <service> -n dev \
  --limits=memory=2Gi

# Restart periódico (workaround temporal)
kubectl rollout restart deployment/<service> -n dev

# Analizar heap dump
kubectl cp dev/<pod-name>:/tmp/heap.hprof ./heap.hprof
# Analizar con VisualVM o Eclipse MAT
```

#### 5. Circuit Breaker Abierto

**Diagnóstico:**
```bash
# Ver estado del circuit breaker
kubectl exec -n dev deploy/<service> -- \
  curl -s http://localhost:8300/actuator/circuitbreakers | jq

# Ver eventos de circuitbreaker
kubectl exec -n dev deploy/<service> -- \
  curl -s http://localhost:8300/actuator/circuitbreakerevents | jq
```

**Soluciones:**
```bash
# Verificar servicio downstream
curl http://<downstream-service>:8400/actuator/health

# Aumentar thresholds temporalmente
kubectl edit configmap <service>-config -n dev
# Ajustar:
# resilience4j.circuitbreaker.configs.default.failureRateThreshold: 70

# Restart para aplicar
kubectl rollout restart deployment/<service> -n dev
```

---

## 🔨 Mantenimiento

### Mantenimiento Semanal

#### 1. Limpieza de Recursos

**📸 Screenshot 47:**
```bash
# Eliminar pods en estado Evicted/Failed
kubectl get pods -n dev --field-selector=status.phase=Failed -o name | \
  xargs kubectl delete -n dev

kubectl get pods -n dev --field-selector=status.phase=Evicted -o name | \
  xargs kubectl delete -n dev

# Limpieza de imágenes no utilizadas
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | \
  sort | uniq > images-in-use.txt

gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/$PROJECT_ID/ecommerce-services \
  --format="value(IMAGE)" > all-images.txt

# Comparar y eliminar imágenes no usadas (manual)
```
> **Archivo:** `screenshots/47-cleanup-resources.png`

#### 2. Actualización de Dependencias

```bash
# Ver versiones actuales
kubectl get deployments -n dev -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}'

# Actualizar base images en Dockerfiles
cd ecommerce-microservice-backend-app
sed -i 's/openjdk:11-jre-slim/openjdk:11.0.21-jre-slim/g' */Dockerfile

# Rebuild y redeploy via Jenkins
git add */Dockerfile
git commit -m "chore: Update base images to latest security patches"
git push origin dev
```

#### 3. Rotación de Secretos

```bash
# Generar nuevos secretos
NEW_DB_PASSWORD=$(openssl rand -base64 32)

# Actualizar secret
kubectl create secret generic db-credentials \
  --from-literal=password=$NEW_DB_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -n dev -f -

# Restart pods que usan el secret
kubectl rollout restart deployment/order-service -n dev
kubectl rollout restart deployment/payment-service -n dev
```

#### 4. Backup de Configuración

```bash
# Backup completo del namespace
kubectl get all,cm,secrets,pvc -n dev -o yaml > \
  backup-dev-$(date +%Y%m%d).yaml

# Comprimir y subir
gzip backup-dev-$(date +%Y%m%d).yaml
gsutil cp backup-dev-$(date +%Y%m%d).yaml.gz \
  gs://$BACKUP_BUCKET/k8s/$(date +%Y)/$(date +%m)/

# Backup de Terraform state
cd terraform/environments/dev
terraform state pull > terraform.tfstate.backup-$(date +%Y%m%d)
gsutil cp terraform.tfstate.backup-$(date +%Y%m%d) \
  gs://$BACKUP_BUCKET/terraform/$(date +%Y)/$(date +%m)/
```

### Mantenimiento Mensual

```bash
# 1. Actualizar certificados SSL/TLS (si aplica)
kubectl get certificates -n dev

# 2. Revisar políticas de red
kubectl get networkpolicies -n dev

# 3. Auditoría de permisos RBAC
kubectl get rolebindings -n dev
kubectl get clusterrolebindings | grep dev

# 4. Análisis de costos
gcloud billing accounts list
# Revisar en GCP Console → Billing → Reports

# 5. Pruebas de disaster recovery
# Simular caída de zona
# kubectl drain <node> --ignore-daemonsets

# 6. Actualizar documentación
git add docs/
git commit -m "docs: Update operational procedures"
git push
```

---

## 🚨 Gestión de Incidentes

### Severidades

| Nivel | Descripción | Tiempo de Respuesta | Ejemplo |
|-------|-------------|---------------------|---------|
| **P0 - Critical** | Sistema completamente caído | 15 minutos | Cluster down, API Gateway no responde |
| **P1 - High** | Funcionalidad crítica afectada | 1 hora | Servicio de pagos caído, datos inconsistentes |
| **P2 - Medium** | Funcionalidad degradada | 4 horas | Latencia alta, logs de errores |
| **P3 - Low** | Impacto mínimo | 24 horas | Documentación desactualizada, warnings |

### Procedimiento de Respuesta

#### P0 - Critical Incident

**📸 Screenshot 48:**
```bash
# 1. IDENTIFICAR
kubectl get pods --all-namespaces | grep -v Running
kubectl get nodes
kubectl cluster-info

# 2. COMUNICAR
echo "INCIDENT DETECTED: $(date)" | tee -a incident-log.txt
# Notificar al equipo via Slack/Email

# 3. MITIGAR
# Rollback inmediato si es por deployment
kubectl rollout undo deployment/<service> -n dev

# O escalar a 0 y volver a escalar
kubectl scale deployment <service> -n dev --replicas=0
kubectl scale deployment <service> -n dev --replicas=3

# 4. DOCUMENTAR
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > \
  incident-$(date +%Y%m%d-%H%M%S)-events.txt
kubectl logs -n dev --all-containers=true > \
  incident-$(date +%Y%m%d-%H%M%S)-logs.txt
```
> **Archivo:** `screenshots/48-incident-response-critical.png`

#### Post-Mortem Template

```markdown
# Post-Mortem: [INCIDENT TITLE]

**Fecha:** 2025-12-01  
**Severidad:** P0 - Critical  
**Duración:** 45 minutos  
**Impacto:** 100% de usuarios afectados

## Resumen
Breve descripción del incidente.

## Timeline
- 14:00: Alerta de Prometheus - API Gateway down
- 14:05: Equipo notificado, investigación iniciada
- 14:15: Causa identificada - OOM en api-gateway
- 14:20: Mitigación aplicada - aumentar límites de memoria
- 14:45: Servicio completamente restaurado

## Causa Raíz
Memory leak en API Gateway v1.5.2 causado por...

## Resolución
- Rollback a v1.5.1
- Aumentar límites de memoria: 512Mi → 1Gi
- Reiniciar pods

## Acciones Preventivas
- [ ] Fix memory leak en código (JIRA-123)
- [ ] Implementar alertas de memoria > 80%
- [ ] Agregar memory profiling en CI/CD
- [ ] Documentar límites recomendados

## Lecciones Aprendidas
1. Alertas de memoria deben ser más agresivas
2. Rollback debe ser automático en P0
3. Load testing debe incluir escenarios de memoria
```

---

## 📚 Comandos de Referencia Rápida

### Kubectl Cheat Sheet

```bash
# PODS
kubectl get pods -n dev                          # Listar pods
kubectl describe pod <pod-name> -n dev           # Detalles de pod
kubectl logs -f <pod-name> -n dev                # Ver logs en tiempo real
kubectl logs <pod-name> -n dev --previous        # Logs de pod anterior
kubectl exec -it <pod-name> -n dev -- /bin/sh   # Shell interactivo
kubectl delete pod <pod-name> -n dev             # Eliminar pod
kubectl top pod <pod-name> -n dev                # Uso de recursos

# DEPLOYMENTS
kubectl get deployments -n dev                   # Listar deployments
kubectl describe deployment <name> -n dev        # Detalles
kubectl scale deployment <name> -n dev --replicas=5  # Escalar
kubectl rollout restart deployment/<name> -n dev # Restart
kubectl rollout status deployment/<name> -n dev  # Estado rollout
kubectl rollout history deployment/<name> -n dev # Historial
kubectl rollout undo deployment/<name> -n dev    # Rollback

# SERVICES
kubectl get svc -n dev                           # Listar servicios
kubectl describe svc <name> -n dev               # Detalles
kubectl get endpoints <name> -n dev              # Ver endpoints

# CONFIGMAPS & SECRETS
kubectl get cm -n dev                            # Listar ConfigMaps
kubectl describe cm <name> -n dev                # Ver ConfigMap
kubectl edit cm <name> -n dev                    # Editar ConfigMap
kubectl get secrets -n dev                       # Listar Secrets

# NODES
kubectl get nodes                                # Listar nodos
kubectl describe node <node-name>                # Detalles de nodo
kubectl top nodes                                # Uso de recursos
kubectl cordon <node-name>                       # Marcar como no schedulable
kubectl drain <node-name> --ignore-daemonsets    # Drenar nodo

# NAMESPACES
kubectl get namespaces                           # Listar namespaces
kubectl config set-context --current --namespace=dev  # Cambiar namespace por defecto

# DEBUG
kubectl run -it --rm debug --image=busybox --restart=Never -- sh  # Pod temporal
kubectl port-forward -n dev svc/<service> 8080:8080  # Port forward
kubectl proxy                                    # Proxy a API server
```

### GCloud Cheat Sheet

```bash
# PROJECTS
gcloud projects list                             # Listar proyectos
gcloud config set project <project-id>           # Establecer proyecto

# GKE
gcloud container clusters list                   # Listar clusters
gcloud container clusters describe <cluster>     # Detalles
gcloud container clusters get-credentials <cluster> --region=us-central1  # Credenciales

# ARTIFACT REGISTRY
gcloud artifacts repositories list               # Listar repositorios
gcloud artifacts docker images list <repo>       # Listar imágenes

# COMPUTE ENGINE
gcloud compute instances list                    # Listar VMs
gcloud compute instances describe <instance>     # Detalles
gcloud compute ssh <instance>                    # SSH a VM

# IAM
gcloud iam service-accounts list                 # Listar service accounts
gcloud projects get-iam-policy <project-id>      # Ver políticas IAM
```

### Docker Commands

```bash
# IMAGES
docker images                                    # Listar imágenes
docker build -t <image>:<tag> .                  # Build imagen
docker tag <image>:<tag> <registry>/<image>:<tag>  # Tag imagen
docker push <registry>/<image>:<tag>             # Push a registry

# CONTAINERS
docker ps                                        # Containers running
docker ps -a                                     # Todos los containers
docker logs -f <container-id>                    # Ver logs
docker exec -it <container-id> /bin/sh           # Shell interactivo
docker stop <container-id>                       # Detener container
docker rm <container-id>                         # Eliminar container

# CLEANUP
docker system prune -a                           # Limpiar todo
docker image prune -a                            # Limpiar imágenes
docker volume prune                              # Limpiar volúmenes
```

---

## 📞 Contactos de Soporte

| Rol | Nombre | Email | Teléfono | Horario |
|-----|--------|-------|----------|---------|
| **DevOps Lead** | David Santiago | dsmalte2002@gmail.com | - | 24/7 (P0) |
| **SRE** | Santiago Ángel | santiago.angel@example.com | - | 8AM-6PM |
| **Backend Lead** | Backend Team | backend@example.com | - | 8AM-6PM |
| **GCP Support** | Google Cloud | - | - | Según plan |

**Escalation Path:**
1. P3/P2: Abrir ticket en JIRA
2. P1: Notificar en Slack #incidents + email
3. P0: Llamar a DevOps Lead + Notificar en todos los canales

---

**✅ Manual de Operaciones Completo**

Para más información consultar:
- [Arquitectura del Sistema](01-ARQUITECTURA.md)
- [Guía de Instalación](02-GUIA-INSTALACION.md)
- [Análisis de Costos](04-COSTOS-INFRAESTRUCTURA.md)
