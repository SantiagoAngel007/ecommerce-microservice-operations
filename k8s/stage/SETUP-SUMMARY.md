# Resumen de Configuración - Stage Namespace

## ✅ Lo que se ha creado

### Infraestructura Central
- ✅ **Config Server** - Centraliza la configuración de todos los microservicios
- ✅ **Zipkin** - Sistema de tracing distribuido para observabilidad
- ✅ **Service Discovery (Eureka)** - Service registry para comunicación inter-servicios
- ✅ **Proxy Client** - API Gateway para enrutar requests

### Microservicios
- ✅ **User Service** - Gestión de usuarios (Puerto 8700)
- ✅ **Product Service** - Catálogo de productos (Puerto 8500)
- ✅ **Order Service** - Gestión de órdenes (Puerto 8300)
- ✅ **Payment Service** - Procesamiento de pagos (Puerto 8400)
- ✅ **Favourite Service** - Gestión de favoritos (Puerto 8800)
- ✅ **Shipping Service** - Logística y envíos (Puerto 8600)

### Secretos y Configuración
- ✅ **Docker Registry Secret** - Para pull de imágenes privadas
- ✅ **ConfigMaps** - Configuración centralizada para cada servicio
- ✅ **Services** - Exposición de puertos internos

### Documentación y Scripts
- ✅ **README.md** - Guía completa del ambiente stage
- ✅ **DEPLOYMENT-GUIDE.md** - Guía paso a paso de despliegue
- ✅ **setup-stage-namespace.sh** - Script automático (Linux/macOS)
- ✅ **setup-stage-namespace.ps1** - Script automático (Windows PowerShell)
- ✅ **secrets/README.md** - Documentación de secretos

## 📁 Estructura de Archivos

```
k8s/stage/
│
├── 📄 README.md                          # Guía principal
├── 📄 DEPLOYMENT-GUIDE.md               # Guía de despliegue paso a paso
├── 📄 SETUP-SUMMARY.md                  # Este archivo
├── 📄 setup-stage-namespace.sh           # Script setup (Linux/macOS)
├── 📄 setup-stage-namespace.ps1          # Script setup (Windows)
│
├── 📁 config-server/                     # Config Server
│   ├── deployment.yaml                  # Despliegue
│   ├── service.yaml                     # Servicio Kubernetes
│   └── configmap.yaml                   # Configuraciones de aplicaciones
│
├── 📁 zipkin/                            # Distributed Tracing
│   ├── deployment.yaml                  # Despliegue
│   └── service.yaml                     # Servicio Kubernetes
│
├── 📁 secrets/                           # Secretos
│   ├── dockerhub-credentials-secret.yaml # Docker Registry Secret
│   └── README.md                        # Guía de secretos
│
├── 📁 service-discovery/                 # Eureka
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 proxy-client/                      # API Gateway
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 user-service/                      # User Service
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 product-service/                   # Product Service
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 order-service/                     # Order Service
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 payment-service/                   # Payment Service
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── 📁 favourite-service/                 # Favourite Service
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
└── 📁 shipping-service/                  # Shipping Service
    ├── deployment.yaml
    ├── service.yaml
    └── configmap.yaml
```

## 🚀 Inicio Rápido

### Opción 1: Setup Automático (Recomendado)

**Windows (PowerShell):**
```powershell
cd k8s\stage
.\setup-stage-namespace.ps1 -DockerUsername "usuario" -DockerToken "token" -DockerEmail "email@example.com"
```

**Linux/macOS:**
```bash
cd k8s/stage
chmod +x setup-stage-namespace.sh
./setup-stage-namespace.sh usuario token email@example.com
```

### Opción 2: Setup Manual

```bash
# 1. Crear namespace y secret
kubectl create namespace stage
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=usuario \
  --docker-password=token \
  --docker-email=email@example.com \
  --namespace=stage

# 2. Desplegar infraestructura
kubectl apply -f config-server/
kubectl apply -f zipkin/
kubectl apply -f service-discovery/

# 3. Desplegar microservicios
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f favourite-service/
kubectl apply -f shipping-service/
kubectl apply -f proxy-client/
```

## ✨ Características Principales

### Config Server
- **Imagen**: `springcloud/configserver:latest`
- **Puerto**: 8888
- **Perfil**: `native` (almacenamiento en memoria en ConfigMap)
- **Incluye configuraciones de**:
  - user-service
  - product-service
  - order-service
  - payment-service
  - favourite-service
  - shipping-service
  - proxy-client

### Zipkin
- **Imagen**: `openzipkin/zipkin:latest`
- **Puerto**: 9411
- **Almacenamiento**: En memoria (temporal)
- **Propósito**: Distributed tracing y observabilidad

### Microservicios
Todos los microservicios tienen:
- ✅ Health checks (liveness + readiness probes)
- ✅ ImagePullSecrets para Docker Hub
- ✅ ConfigMaps para configuración centralizada
- ✅ Eureka registration habilitado
- ✅ Zipkin tracing habilitado
- ✅ Recursos requests/limits configurados
- ✅ Base de datos H2 en memoria

## 📋 Configuración de Cada Servicio

| Servicio | Puerto | Context Path | Eureka | Zipkin | Config Server |
|----------|--------|--------------|--------|--------|---------------|
| User | 8700 | /user-service | ✅ | ✅ | ✅ |
| Product | 8500 | /product-service | ✅ | ✅ | ✅ |
| Order | 8300 | /order-service | ✅ | ✅ | ✅ |
| Payment | 8400 | /payment-service | ✅ | ✅ | ✅ |
| Favourite | 8800 | /favourite-service | ✅ | ✅ | ✅ |
| Shipping | 8600 | /shipping-service | ✅ | ✅ | ✅ |
| Proxy Client | 8200 | / | ✅ | ✅ | ✅ |
| Config Server | 8888 | / | - | - | - |
| Zipkin | 9411 | / | - | - | - |
| Service Discovery | 8761 | / | - | - | - |

## 🔐 Secretos Configurados

### dockerhub-credentials
- **Tipo**: kubernetes.io/dockercfg
- **Propósito**: Autenticación con Docker Hub para descargar imágenes
- **Campos**: docker-server, docker-username, docker-password, docker-email
- **Usado por**: Todos los deployments

## 📊 Recursos Configurados

### Requests (Garantizados)
- **Memoria**: 256Mi por servicio
- **CPU**: 100m por servicio
- **Excepto Zipkin**: 512Mi / 200m

### Limits (Máximo)
- **Memoria**: 512Mi por servicio
- **CPU**: 250m por servicio
- **Excepto Zipkin**: 1Gi / 500m

## ⏱️ Health Checks

### Liveness Probe
- **Delay inicial**: 60 segundos
- **Período**: 10 segundos
- **Timeout**: 5 segundos
- **Fallos**: 3 reintentos antes de reinicio

### Readiness Probe
- **Delay inicial**: 30 segundos
- **Período**: 5 segundos
- **Timeout**: 3 segundos
- **Fallos**: 2 reintentos antes de marcar no listo

## 🔄 Service Discovery

Todos los servicios están configurados para registrarse con **Eureka**:
- **Server**: http://service-discovery:8761/eureka/
- **Hostname**: nombre del servicio
- **Prefer IP Address**: false

## 📊 Tracing Distribuido

Todos los servicios están configurados para enviar traces a **Zipkin**:
- **URL**: http://zipkin:9411/
- **Propósito**: Visualizar flujos de request entre microservicios

## 💾 Persistencia

- **Bases de datos**: H2 en memoria (no persistente)
- **Configuración**: En ConfigMaps de Kubernetes
- **Zipkin traces**: En memoria (se pierden al reiniciar)

⚠️ **Para producción**, considera usar:
- PostgreSQL/MySQL en lugar de H2
- PersistentVolumes para datos críticos
- Distributed Zipkin storage (ElasticSearch, etc.)

## 📝 Próximos Pasos

1. **Ejecutar setup**:
   ```bash
   .\setup-stage-namespace.ps1 -DockerUsername "tu_usuario" -DockerToken "tu_token" -DockerEmail "tu_email"
   ```

2. **Verificar despliegue**:
   ```bash
   kubectl get all -n stage
   ```

3. **Acceder a servicios**:
   ```bash
   # Port-forward
   kubectl port-forward -n stage svc/proxy-client 8200:8200
   kubectl port-forward -n stage svc/zipkin 9411:9411

   # Luego acceder a:
   # - Proxy Client: http://localhost:8200
   # - Zipkin: http://localhost:9411
   ```

4. **Ejecutar pruebas**:
   - Pruebas de integración
   - Pruebas E2E
   - Pruebas de carga

## 📚 Documentación

- **README.md**: Guía completa de uso
- **DEPLOYMENT-GUIDE.md**: Pasos detallados de despliegue
- **secrets/README.md**: Gestión de secretos
- **kubernetes.md**: Documentación general de Kubernetes

## 🆘 Soporte

### Verificar logs
```bash
kubectl logs -n stage -l app=user-service
kubectl logs -f -n stage -l app=config-server
```

### Describir recursos
```bash
kubectl describe deployment user-service -n stage
kubectl describe pod -n stage pod/user-service-xxxxx
```

### Ver eventos
```bash
kubectl get events -n stage --sort-by='.lastTimestamp'
```

## 📞 Contacto

Si encuentras problemas:
1. Revisa los logs: `kubectl logs -n stage -l app=<servicio>`
2. Verifica los events: `kubectl get events -n stage`
3. Lee la documentación en README.md
4. Consulta DEPLOYMENT-GUIDE.md para pasos específicos

---

**Creado**: 30 de Octubre 2024
**Versión**: 1.0
**Ambiente**: Stage (Pre-producción)
**Cluster**: Kubernetes (Minikube / Docker Desktop / Cloud)
