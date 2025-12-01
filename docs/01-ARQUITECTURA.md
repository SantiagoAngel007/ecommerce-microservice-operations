# 🏗️ Arquitectura del Sistema E-Commerce Microservices

**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Autores:** David Santiago Malte, Santiago Ángel, Samuel Ibarra

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura de Alto Nivel](#arquitectura-de-alto-nivel)
3. [Arquitectura de Microservicios](#arquitectura-de-microservicios)
4. [Arquitectura de Infraestructura](#arquitectura-de-infraestructura)
5. [Patrones de Diseño Implementados](#patrones-de-diseño-implementados)
6. [Flujos de Comunicación](#flujos-de-comunicación)
7. [Decisiones Técnicas](#decisiones-técnicas)
8. [Screenshots de Arquitectura](#screenshots-de-arquitectura)

---

## 📖 Introducción

Este documento describe la arquitectura completa del sistema de e-commerce basado en microservicios, desplegado en Google Cloud Platform utilizando Kubernetes (GKE) y siguiendo las mejores prácticas de diseño cloud-native.

### Objetivos de la Arquitectura

- ✅ **Escalabilidad horizontal**: Cada microservicio puede escalar independientemente
- ✅ **Alta disponibilidad**: Múltiples réplicas y health checks automatizados
- ✅ **Resiliencia**: Circuit breakers y fallbacks para tolerancia a fallos
- ✅ **Observabilidad**: Logs centralizados, métricas y distributed tracing
- ✅ **Despliegue continuo**: CI/CD automatizado con Jenkins
- ✅ **Seguridad**: Network policies, secrets management, RBAC

---

## 🎯 Arquitectura de Alto Nivel

### Vista General del Sistema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                USUARIOS                                  │
│                         (Web / Mobile / API)                             │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTPS
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          GOOGLE CLOUD PLATFORM                           │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Cloud Load Balancer                         │   │
│  │                    (External IP: 35.x.x.x)                       │   │
│  └────────────────────────────┬────────────────────────────────────┘   │
│                                │                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    GKE AUTOPILOT CLUSTER                         │   │
│  │                   (us-central1, Regional)                        │   │
│  │                                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │                  NAMESPACE: dev                          │   │   │
│  │  │                                                           │   │   │
│  │  │  ┌───────────────────────────────────────────────────┐  │   │   │
│  │  │  │         INFRASTRUCTURE LAYER                      │  │   │   │
│  │  │  │                                                     │  │   │   │
│  │  │  │  ┌─────────────┐        ┌─────────────┐          │  │   │   │
│  │  │  │  │  API        │        │  Service    │          │  │   │   │
│  │  │  │  │  Gateway    │◄───────│  Discovery  │          │  │   │   │
│  │  │  │  │  (Proxy)    │        │  (Eureka)   │          │  │   │   │
│  │  │  │  │  Port: 8200 │        │  Port: 8761 │          │  │   │   │
│  │  │  │  └──────┬──────┘        └─────────────┘          │  │   │   │
│  │  │  │         │                                         │  │   │   │
│  │  │  │  ┌──────┴───────┐        ┌─────────────┐        │  │   │   │
│  │  │  │  │  Config      │        │   Zipkin    │        │  │   │   │
│  │  │  │  │  Server      │        │  (Tracing)  │        │  │   │   │
│  │  │  │  │  Port: 8888  │        │  Port: 9411 │        │  │   │   │
│  │  │  │  └──────────────┘        └─────────────┘        │  │   │   │
│  │  │  └─────────────────────────────────────────────────┘  │   │   │
│  │  │                                                         │   │   │
│  │  │  ┌───────────────────────────────────────────────────┐│   │   │
│  │  │  │         BUSINESS SERVICES LAYER                   ││   │   │
│  │  │  │                                                     ││   │   │
│  │  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        ││   │   │
│  │  │  │  │  User    │  │ Product  │  │  Order   │        ││   │   │
│  │  │  │  │ Service  │  │ Service  │  │ Service  │        ││   │   │
│  │  │  │  │Port: 8700│  │Port: 8500│  │Port: 8300│        ││   │   │
│  │  │  │  └──────────┘  └──────────┘  └──────────┘        ││   │   │
│  │  │  │                                                     ││   │   │
│  │  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        ││   │   │
│  │  │  │  │ Payment  │  │ Shipping │  │ Favourite│        ││   │   │
│  │  │  │  │ Service  │  │ Service  │  │ Service  │        ││   │   │
│  │  │  │  │Port: 8400│  │Port: 8600│  │Port: 8800│        ││   │   │
│  │  │  │  └──────────┘  └──────────┘  └──────────┘        ││   │   │
│  │  │  └───────────────────────────────────────────────────┘│   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     ARTIFACT REGISTRY                            │   │
│  │           (Docker Images: us-central1-docker.pkg.dev)            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     CLOUD STORAGE                                │   │
│  │            (Terraform State Backend: gs://...)                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────┐
│                            CI/CD PIPELINE                                  │
│  ┌─────────────────────────────────────────────────────────────────┐     │
│  │  Jenkins Server (Compute Engine VM: e2-standard-2)              │     │
│  │  IP: 34.123.43.189:8080                                          │     │
│  │  • GitHub Webhooks → Automated Builds                            │     │
│  │  • Maven Build → JUnit Tests → Trivy Scan                        │     │
│  │  • Docker Build → Push to Artifact Registry                      │     │
│  │  • kubectl apply → Deploy to GKE                                 │     │
│  └─────────────────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────────────────┘
```

### **Screenshot**
```bash
# Comando para capturar arquitectura general
gcloud compute instances list
gcloud container clusters list
kubectl get namespaces
kubectl get all -n dev
``` 
> **Descripción:** Vista de todos los recursos desplegados en GCP

---

## 🔧 Arquitectura de Microservicios

### Descripción de Microservicios

#### 1. **Infrastructure Services**

##### a) Service Discovery (Eureka Server)
- **Puerto:** 8761
- **Propósito:** Registro y descubrimiento de servicios
- **Tecnología:** Spring Cloud Netflix Eureka
- **Réplicas:** 2 (alta disponibilidad)
- **Dependencias:** Ninguna

**Funcionalidad:**
- Registro automático de servicios al iniciar
- Health checks periódicos
- Balanceo de carga cliente-side
- Failover automático

**Screenshot Requerido**
```bash
# Acceder a Eureka Dashboard
kubectl get svc -n dev service-discovery
# Abrir navegador en: http://<EXTERNAL-IP>:8761
```
> **Archivo:** `screenshots/02-eureka-dashboard.png`  
> **Descripción:** Dashboard de Eureka mostrando todos los servicios registrados

##### b) Config Server
- **Puerto:** 8888
- **Propósito:** Configuración centralizada
- **Tecnología:** Spring Cloud Config Server
- **Backend:** Git repository o Cloud Storage
- **Réplicas:** 1 (suficiente para DEV)

**Configuraciones gestionadas:**
- Application properties por ambiente
- Database connections
- Service URLs
- Feature toggles

##### c) API Gateway (Proxy Client)
- **Puerto:** 8200
- **Propósito:** Punto de entrada único
- **Tecnología:** Spring Cloud Gateway
- **Funcionalidades:**
  - Routing dinámico
  - Load balancing
  - Rate limiting
  - Authentication/Authorization (futuro)

**Rutas configuradas:**
```yaml
/api/user-service/**    → user-service:8700
/api/product-service/** → product-service:8500
/api/order-service/**   → order-service:8300
/api/payment-service/** → payment-service:8400
/api/shipping-service/** → shipping-service:8600
/api/favourite-service/** → favourite-service:8800
```

**Screenshot**
```bash
# Test de routing del API Gateway
curl http://<API-GATEWAY-IP>:8200/api/user-service/users
curl http://<API-GATEWAY-IP>:8200/api/product-service/products
curl http://<API-GATEWAY-IP>:8200/actuator/gateway/routes | jq
```

##### d) Zipkin (Distributed Tracing)
- **Puerto:** 9411
- **Propósito:** Rastreo de transacciones distribuidas
- **Tecnología:** Zipkin Server
- **Storage:** In-memory (DEV), Elasticsearch (PROD)

**📸 Screenshot Requerido 4:**
```bash
# Acceder a Zipkin UI
kubectl get svc -n dev zipkin
# Navegar a: http://<EXTERNAL-IP>:9411
# Hacer una transacción de prueba
curl http://<API-GATEWAY-IP>:8200/api/order-service/orders
# Refresh Zipkin y capturar trace
```
> **Archivo:** `screenshots/04-zipkin-trace.png`  
> **Descripción:** Trace de una transacción completa (user → product → order → payment)

#### 2. **Business Services**

##### a) User Service
- **Puerto:** 8700
- **Base de Datos:** MySQL/PostgreSQL
- **Endpoints principales:**
  - `GET /users` - Listar usuarios
  - `GET /users/{id}` - Obtener usuario
  - `POST /users` - Crear usuario
  - `PUT /users/{id}` - Actualizar usuario
  - `DELETE /users/{id}` - Eliminar usuario

**Dependencias:**
- Service Discovery (para registro)
- Config Server (para configuración)

##### b) Product Service
- **Puerto:** 8500
- **Base de Datos:** MySQL/PostgreSQL
- **Endpoints principales:**
  - `GET /products` - Catálogo de productos
  - `GET /products/{id}` - Detalle de producto
  - `POST /products` - Crear producto
  - `PUT /products/{id}/stock` - Actualizar inventario

**Patrones implementados:**
- ✅ **Circuit Breaker** (Resilience4j)
- ✅ **Retry** con exponential backoff
- ✅ **Bulkhead** para aislamiento de recursos

##### c) Order Service
- **Puerto:** 8300
- **Base de Datos:** MySQL/PostgreSQL
- **Endpoints principales:**
  - `POST /orders` - Crear pedido
  - `GET /orders/{id}` - Consultar pedido
  - `PUT /orders/{id}/status` - Actualizar estado

**Comunicación con otros servicios:**
```
Order Service → Product Service (verificar stock)
Order Service → Payment Service (procesar pago)
Order Service → Shipping Service (crear envío)
```

**📸 Screenshot Requerido 5:**
```bash
# Flujo completo de orden
# 1. Crear orden
curl -X POST http://<API-GATEWAY-IP>:8200/api/order-service/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "products": [{"id": 1, "quantity": 2}],
    "total": 99.99
  }'

# 2. Ver logs del flujo en Zipkin
# Capturar el trace que muestra:
# Order Service → Product Service → Payment Service → Shipping Service
```
> **Archivo:** `screenshots/05-order-flow-trace.png`

##### d) Payment Service
- **Puerto:** 8400
- **Integración:** Stripe/PayPal (simulado)
- **Endpoints principales:**
  - `POST /payments` - Procesar pago
  - `GET /payments/{id}` - Estado de pago
  - `POST /payments/{id}/refund` - Reembolso

**Circuit Breaker configurado:**
```java
@CircuitBreaker(name = "payment-service", fallbackMethod = "paymentFallback")
public PaymentResponse processPayment(PaymentRequest request) {
    // Lógica de pago
}

public PaymentResponse paymentFallback(PaymentRequest request, Exception e) {
    return PaymentResponse.builder()
        .status("PENDING")
        .message("Payment service temporarily unavailable")
        .build();
}
```

##### e) Shipping Service
- **Puerto:** 8600
- **Integración:** FedEx/UPS (simulado)
- **Endpoints principales:**
  - `POST /shipments` - Crear envío
  - `GET /shipments/{id}` - Rastrear envío
  - `PUT /shipments/{id}/status` - Actualizar estado

##### f) Favourite Service
- **Puerto:** 8800
- **Propósito:** Lista de favoritos de usuarios
- **Endpoints principales:**
  - `GET /favourites/user/{userId}` - Lista de favoritos
  - `POST /favourites` - Agregar favorito
  - `DELETE /favourites/{id}` - Eliminar favorito

---

## ☁️ Arquitectura de Infraestructura

### Google Cloud Platform Resources

#### 1. **GKE Autopilot Cluster**

**Configuración DEV:**
```hcl
resource "google_container_cluster" "ecommerce_dev" {
  name     = "ecommerce-dev-cluster"
  location = "us-central1"
  
  enable_autopilot = true
  
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.0.0.0/16"
    services_ipv4_cidr_block = "10.1.0.0/16"
  }
  
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T00:00:00Z"
      end_time   = "2024-01-01T04:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SU"
    }
  }
}
```

**Características:**
- ✅ Auto-scaling de nodos
- ✅ Auto-repair de nodos
- ✅ Auto-upgrade de versión K8s
- ✅ Optimización de costos (solo pagas por pods activos)
- ✅ Security by default (Workload Identity, Network Policies)

**📸 Screenshot Requerido 6:**
```bash
# Detalles del cluster
gcloud container clusters describe ecommerce-dev-cluster \
  --region=us-central1 \
  --format=yaml

# Nodes y recursos
kubectl top nodes
kubectl describe nodes
```
> **Archivo:** `screenshots/06-gke-cluster-details.png`

#### 2. **VPC Networking**

**Configuración:**
```
VPC Name: ecommerce-vpc
Subnets:
  - dev-subnet: 10.0.1.0/24 (us-central1)
  - stage-subnet: 10.0.2.0/24 (us-central1)
  - prod-subnet: 10.0.3.0/24 (us-central1, us-east1)

Firewall Rules:
  - allow-http: 0.0.0.0/0 → tcp:80,8080,8200
  - allow-https: 0.0.0.0/0 → tcp:443
  - allow-health-checks: GCP health checkers
  - deny-all-ingress: default deny
```

**📸 Screenshot Requerido 7:**
```bash
# VPC y subnets
gcloud compute networks describe ecommerce-vpc
gcloud compute networks subnets list --network=ecommerce-vpc

# Firewall rules
gcloud compute firewall-rules list --filter="network:ecommerce-vpc"
```
> **Archivo:** `screenshots/07-vpc-networking.png`

#### 3. **Artifact Registry**

**Configuración:**
```
Repository: ecommerce-services
Format: Docker
Location: us-central1
Description: Docker images para microservicios

Images stored:
  - service-discovery:dev-17
  - config-server:dev-17
  - api-gateway:dev-17
  - user-service:dev-17
  - product-service:dev-17
  - order-service:dev-17
  - payment-service:dev-17
  - shipping-service:dev-17
  - favourite-service:dev-17
```

**📸 Screenshot Requerido 8:**
```bash
# Listar imágenes en Artifact Registry
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/PROJECT_ID/ecommerce-services

# Detalles de una imagen
gcloud artifacts docker images describe \
  us-central1-docker.pkg.dev/PROJECT_ID/ecommerce-services/user-service:dev-17
```
> **Archivo:** `screenshots/08-artifact-registry.png`

#### 4. **Compute Engine (Jenkins)**

**VM Configuration:**
```
Name: jenkins-server
Machine Type: e2-standard-2 (2 vCPUs, 8 GB memory)
Zone: us-central1-a
Disk: 50 GB SSD persistent disk
OS: Ubuntu 22.04 LTS
Network: ecommerce-vpc
External IP: 34.123.43.189 (static)

Installed Software:
  - Jenkins 2.4xx
  - Docker 24.0.x
  - kubectl 1.28.x
  - gcloud SDK
  - Terraform 1.5.x
```

**📸 Screenshot Requerido 9:**
```bash
# Detalles de la VM Jenkins
gcloud compute instances describe jenkins-server \
  --zone=us-central1-a

# SSH y verificar servicios
gcloud compute ssh jenkins-server --zone=us-central1-a
systemctl status jenkins
docker --version
kubectl version --client
```
> **Archivo:** `screenshots/09-jenkins-vm.png`

---

## 🎨 Patrones de Diseño Implementados

### 1. **Circuit Breaker Pattern** (Resilience4j)

**Implementación en Product Service:**

```java
@Service
public class ProductService {
    
    @CircuitBreaker(
        name = "productService",
        fallbackMethod = "getProductsFallback"
    )
    @Retry(name = "productService", fallbackMethod = "getProductsFallback")
    @Bulkhead(name = "productService")
    public List<Product> getProducts() {
        // Lógica de negocio
        return productRepository.findAll();
    }
    
    // Fallback method
    public List<Product> getProductsFallback(Exception e) {
        log.warn("Circuit breaker activated for getProducts: {}", e.getMessage());
        return getCachedProducts(); // Retornar productos en caché
    }
}
```

**Configuración (application.yml):**

```yaml
resilience4j:
  circuitbreaker:
    instances:
      productService:
        registerHealthIndicator: true
        slidingWindowSize: 10
        minimumNumberOfCalls: 5
        permittedNumberOfCallsInHalfOpenState: 3
        automaticTransitionFromOpenToHalfOpenEnabled: true
        waitDurationInOpenState: 10s
        failureRateThreshold: 50
        eventConsumerBufferSize: 10
        
  retry:
    instances:
      productService:
        maxAttempts: 3
        waitDuration: 1s
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2
        
  bulkhead:
    instances:
      productService:
        maxConcurrentCalls: 10
        maxWaitDuration: 500ms
```

**📸 Screenshot Requerido 10:**
```bash
# Simular fallo y activar circuit breaker
# 1. Hacer el servicio fallar temporalmente
kubectl scale deployment product-service --replicas=0 -n dev

# 2. Hacer requests al API Gateway
for i in {1..20}; do
  curl http://<API-GATEWAY-IP>:8200/api/product-service/products
  echo ""
done

# 3. Verificar métricas de Resilience4j en Actuator
curl http://<PRODUCT-SERVICE-IP>:8500/actuator/health | jq
curl http://<PRODUCT-SERVICE-IP>:8500/actuator/metrics/resilience4j.circuitbreaker.state | jq

# 4. Restaurar servicio
kubectl scale deployment product-service --replicas=2 -n dev
```
> **Archivo:** `screenshots/10-circuit-breaker-demo.png`  
> **Descripción:** Captura mostrando circuit breaker activado (OPEN state) y fallback funcionando

### 2. **Feature Toggle Pattern**

**Implementación en Order Service:**

```java
@RestController
@RequestMapping("/orders")
public class OrderController {
    
    @Value("${features.express-shipping.enabled:false}")
    private boolean expressShippingEnabled;
    
    @Value("${features.payment-installments.enabled:false}")
    private boolean paymentInstallmentsEnabled;
    
    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@RequestBody OrderRequest request) {
        
        // Feature toggle para envío express
        if (expressShippingEnabled && request.isExpressShipping()) {
            order.setShippingType(ShippingType.EXPRESS);
            order.setShippingCost(calculateExpressCost());
        } else {
            order.setShippingType(ShippingType.STANDARD);
            order.setShippingCost(calculateStandardCost());
        }
        
        // Feature toggle para pagos en cuotas
        if (paymentInstallmentsEnabled && request.getInstallments() > 1) {
            paymentRequest.setInstallments(request.getInstallments());
        }
        
        return orderService.processOrder(order);
    }
}
```

**Configuración dinámica (ConfigMap K8s):**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
  namespace: dev
data:
  application.yaml: |
    features:
      express-shipping:
        enabled: true
        max-weight-kg: 50
      payment-installments:
        enabled: false
        max-installments: 12
        min-amount: 100
```

**📸 Screenshot Requerido 11:**
```bash
# 1. Verificar feature toggles actuales
kubectl get configmap order-service-config -n dev -o yaml

# 2. Hacer request con feature deshabilitado
curl -X POST http://<API-GATEWAY-IP>:8200/api/order-service/orders \
  -H "Content-Type: application/json" \
  -d '{"expressShipping": true}' # Debe ignorarse

# 3. Habilitar feature
kubectl edit configmap order-service-config -n dev
# Cambiar express-shipping.enabled a true

# 4. Restart pods para recargar config
kubectl rollout restart deployment order-service -n dev

# 5. Hacer request nuevamente (ahora debe funcionar)
curl -X POST http://<API-GATEWAY-IP>:8200/api/order-service/orders \
  -H "Content-Type: application/json" \
  -d '{"expressShipping": true}'
```
> **Archivo:** `screenshots/11-feature-toggle-demo.png`  
> **Descripción:** Comparación de respuestas con feature habilitado vs deshabilitado

### 3. **API Gateway Pattern**

Ya documentado en sección de microservicios.

### 4. **Service Registry Pattern** (Eureka)

Ya documentado en sección de microservicios.

### 5. **Centralized Configuration Pattern**

Ya documentado en sección de microservicios.

---

## 🔄 Flujos de Comunicación

### Flujo 1: Creación de Orden Completa

```
┌────────┐     ┌────────────┐     ┌──────────────┐     ┌─────────────┐
│ Client │────▶│ API Gateway│────▶│ Order Service│────▶│User Service │
└────────┘     └────────────┘     └──────┬───────┘     └─────────────┘
                                          │
                                          │ 2. Verificar stock
                                          ▼
                                   ┌───────────────┐
                                   │Product Service│
                                   └───────┬───────┘
                                          │
                                          │ 3. Procesar pago
                                          ▼
                                   ┌───────────────┐
                                   │Payment Service│
                                   └───────┬───────┘
                                          │
                                          │ 4. Crear envío
                                          ▼
                                   ┌───────────────┐
                                   │Shipping Service│
                                   └───────────────┘

Tiempo total: ~500ms (p95)
Puntos de observabilidad: Zipkin trace completo
```

**📸 Screenshot Requerido 12:**
```bash
# Ejecutar flujo completo y capturar en Zipkin
# Ver sección anterior de Order Service
```
> **Archivo:** `screenshots/12-order-flow-complete.png`

### Flujo 2: Service Discovery y Load Balancing

```
┌─────────────┐          ┌────────────────┐          ┌─────────────┐
│Order Service│         │Service Discovery│         │Product Svc  │
│  (Startup)  │────1───▶│    (Eureka)     │◀────2───│ Instance 1  │
└─────────────┘         └────────────────┘         └─────────────┘
                                ▲                            ▲
                                │                            │
                                │         3. Heartbeat       │
                                │            every 30s       │
                                │                            │
                        ┌───────┴──────┐          ┌────────┴────────┐
                        │Product Svc   │          │Product Svc      │
                        │Instance 2    │          │Instance 3       │
                        └──────────────┘          └─────────────────┘

Cliente-side load balancing:
  - Round robin por defecto
  - Health-aware routing
  - Automatic failover
```

---

## 🤔 Decisiones Técnicas

### 1. **¿Por qué GKE Autopilot en lugar de GKE Standard?**

**Decisión:** GKE Autopilot  
**Razones:**
- ✅ Menor complejidad operacional (Google gestiona nodos)
- ✅ Pay-per-pod en lugar de pay-per-node
- ✅ Security by default (Workload Identity, Binary Authorization)
- ✅ Auto-scaling sin configuración manual
- ❌ Trade-off: Menos control sobre configuración de nodos

**Alternativa considerada:** GKE Standard  
**Por qué no:** Mayor complejidad, requiere gestión manual de node pools

---

### 2. **¿Por qué Spring Cloud Netflix en lugar de Istio Service Mesh?**

**Decisión:** Spring Cloud Netflix (Eureka, Config Server)  
**Razones:**
- ✅ Más simple para equipos Java/Spring Boot
- ✅ Menos overhead de infraestructura
- ✅ Integración nativa con ecosystem Spring
- ❌ Trade-off: Menos features avanzados (traffic routing, circuit breaking a nivel de infraestructura)

**Alternativa considerada:** Istio + Envoy  
**Por qué no:** Overhead significativo para proyecto de tamaño mediano, curva de aprendizaje mayor

---

### 3. **¿Por qué Terraform en lugar de Deployment Manager (nativo GCP)?**

**Decisión:** Terraform  
**Razones:**
- ✅ Multi-cloud (portabilidad futura)
- ✅ Ecosystem más grande (providers, modules)
- ✅ Mejor soporte de la comunidad
- ✅ HCL más legible que YAML de Deployment Manager

**Alternativa considerada:** Google Cloud Deployment Manager  
**Por qué no:** Lock-in con GCP, menos flexible

---

### 4. **¿Por qué Jenkins en lugar de GitLab CI o GitHub Actions?**

**Decisión:** Jenkins  
**Razones:**
- ✅ Control total sobre pipeline (self-hosted)
- ✅ Plugins extensivos (Docker, Kubernetes, GCP)
- ✅ Groovy pipelines muy flexibles
- ❌ Trade-off: Mayor mantenimiento

**Alternativas consideradas:**
- GitHub Actions: Más simple pero menos control
- GitLab CI: Requiere GitLab instance

---

### 5. **¿Por qué separar repos de backend y operations?**

**Decisión:** 2 repositorios separados  
**Backend:** `ecommerce-microservice-backend-app`  
**Operations:** `ecommerce-microservice-operations`

**Razones:**
- ✅ Separation of concerns (código vs infraestructura)
- ✅ Diferentes ciclos de vida
- ✅ Permisos diferentes (devs vs devops)
- ✅ CI/CD independiente

**Alternativa considerada:** Monorepo  
**Por qué no:** Más complejo de gestionar, builds más lentos

---

## 📊 Screenshots de Arquitectura

### Checklist de Capturas Obligatorias

- [ ] **01-arquitectura-general.png** - Vista de recursos GCP
- [ ] **02-eureka-dashboard.png** - Dashboard de Service Discovery
- [ ] **03-api-gateway-routes.png** - Configuración de rutas
- [ ] **04-zipkin-trace.png** - Trace de transacción distribuida
- [ ] **05-order-flow-trace.png** - Flujo completo de orden
- [ ] **06-gke-cluster-details.png** - Detalles del cluster
- [ ] **07-vpc-networking.png** - VPC y subnets
- [ ] **08-artifact-registry.png** - Imágenes Docker
- [ ] **09-jenkins-vm.png** - VM Jenkins y servicios
- [ ] **10-circuit-breaker-demo.png** - Circuit Breaker activado
- [ ] **11-feature-toggle-demo.png** - Feature Toggle funcionando
- [ ] **12-order-flow-complete.png** - Flujo end-to-end

**Total:** 12 screenshots obligatorios de arquitectura

---

## 📚 Referencias

- [Martin Fowler - Microservices Architecture](https://martinfowler.com/articles/microservices.html)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
- [Kubernetes Patterns Book](https://www.redhat.com/en/resources/cloud-native-container-design-whitepaper)
- [Resilience4j Documentation](https://resilience4j.readme.io/)

---

## 📝 Notas Finales

Este documento de arquitectura debe actualizarse cuando:
- Se agreguen nuevos microservicios
- Se cambien patrones de diseño
- Se modifique la infraestructura cloud
- Se tomen nuevas decisiones técnicas importantes

**Última actualización:** Diciembre 2025  
**Próxima revisión:** Enero 2026
