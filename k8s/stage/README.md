# Kubernetes Stage Environment - Configuración

Esta carpeta contiene todos los manifiestos necesarios para desplegar los microservicios en el ambiente de **staging**.

## Contenido

```
stage/
├── config-server/              # Config Server para centralizar configuración
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── zipkin/                     # Zipkin para distributed tracing
│   ├── deployment.yaml
│   └── service.yaml
│
├── secrets/                    # Secretos de Kubernetes
│   ├── dockerhub-credentials-secret.yaml
│   └── README.md
│
├── user-service/               # Microservicio: User Service
├── product-service/            # Microservicio: Product Service
├── order-service/              # Microservicio: Order Service
├── payment-service/            # Microservicio: Payment Service
├── favourite-service/          # Microservicio: Favourite Service
├── shipping-service/           # Microservicio: Shipping Service
├── service-discovery/          # Eureka Service Discovery
├── proxy-client/               # API Gateway / Proxy
│
├── setup-stage-namespace.sh    # Script de setup (Linux/macOS)
├── setup-stage-namespace.ps1   # Script de setup (Windows)
└── README.md                   # Este archivo
```

## Requisitos Previos

- Kubernetes cluster (Minikube, Docker Desktop, etc.) con acceso a través de kubectl
- kubectl configurado correctamente
- Acceso a Docker Hub (o un registro privado de imágenes)

## Configuración Inicial

### Opción 1: Instalación Automática (Recomendado)

#### En Linux/macOS:
```bash
chmod +x setup-stage-namespace.sh
./setup-stage-namespace.sh tu_usuario tu_token tu_email@example.com
```

#### En Windows (PowerShell):
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\setup-stage-namespace.ps1 -DockerUsername "tu_usuario" -DockerToken "tu_token" -DockerEmail "tu_email@example.com"
```

### Opción 2: Instalación Manual

#### Paso 1: Crear el namespace
```bash
kubectl create namespace stage
```

#### Paso 2: Crear el secret de Docker Registry
```bash
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=tu_usuario \
  --docker-password=tu_token \
  --docker-email=tu_email@example.com \
  --namespace=stage
```

#### Paso 3: Desplegar Config Server
```bash
kubectl apply -f config-server/configmap.yaml
kubectl apply -f config-server/service.yaml
kubectl apply -f config-server/deployment.yaml
```

#### Paso 4: Desplegar Zipkin
```bash
kubectl apply -f zipkin/service.yaml
kubectl apply -f zipkin/deployment.yaml
```

#### Paso 5: Desplegar Service Discovery (Eureka)
```bash
kubectl apply -f service-discovery/
```

#### Paso 6: Desplegar Proxy Client
```bash
kubectl apply -f proxy-client/
```

#### Paso 7: Desplegar los microservicios
```bash
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f favourite-service/
kubectl apply -f shipping-service/
```

## Despliegue Rápido

Una vez que el namespace esté configurado, puedes desplegar todos los microservicios de una vez:

```bash
kubectl apply -f .
```

O de forma selectiva:
```bash
kubectl apply -f user-service/
kubectl apply -f product-service/
kubectl apply -f order-service/
kubectl apply -f payment-service/
kubectl apply -f favourite-service/
kubectl apply -f shipping-service/
```

## Verificación

### Ver estado general
```bash
kubectl get all -n stage
```

### Ver pods
```bash
kubectl get pods -n stage
kubectl get pods -n stage -o wide  # Con más detalles
```

### Ver servicios
```bash
kubectl get svc -n stage
```

### Ver deployments
```bash
kubectl get deployments -n stage
```

### Ver logs
```bash
# Logs de un pod específico
kubectl logs -n stage pod/user-service-xxxxx

# Logs en tiempo real
kubectl logs -f -n stage pod/user-service-xxxxx

# Logs de todos los pods de un servicio
kubectl logs -n stage -l app=user-service --all-containers=true --timestamps=true
```

### Ver eventos
```bash
kubectl get events -n stage --sort-by='.lastTimestamp'
```

## Servicios Disponibles

### Config Server
- **URL interna**: http://config-server:8888
- **Puerto**: 8888
- **Propósito**: Centraliza la configuración de todos los microservicios

### Zipkin
- **URL interna**: http://zipkin:9411
- **Puerto**: 9411
- **Propósito**: Distributed tracing para observabilidad

### Eureka Service Discovery
- **Nombre**: service-discovery
- **Puerto**: 8761
- **Propósito**: Service discovery para inter-service communication

### Microservicios

| Servicio | Puerto | Context Path | URL Interna |
|----------|--------|--------------|-------------|
| User Service | 8700 | /user-service | http://user-service:8700 |
| Product Service | 8500 | /product-service | http://product-service:8500 |
| Order Service | 8300 | /order-service | http://order-service:8300 |
| Payment Service | 8400 | /payment-service | http://payment-service:8400 |
| Favourite Service | 8800 | /favourite-service | http://favourite-service:8800 |
| Shipping Service | 8600 | /shipping-service | http://shipping-service:8600 |
| Proxy Client | 8200 | / | http://proxy-client:8200 |

## Acceder a los Servicios

### Port-Forward (Desarrollo Local)

```bash
# Proxy Client
kubectl port-forward -n stage svc/proxy-client 8200:8200

# User Service
kubectl port-forward -n stage svc/user-service 8700:8700

# Zipkin
kubectl port-forward -n stage svc/zipkin 9411:9411

# Config Server
kubectl port-forward -n stage svc/config-server 8888:8888
```

Luego accede a:
- Proxy Client: http://localhost:8200
- User Service: http://localhost:8700/user-service
- Zipkin: http://localhost:9411
- Config Server: http://localhost:8888

### Ingress (Producción)

Para ambiente de producción, configura un Ingress controller para exponer los servicios.

## Variables de Entorno

### Docker Hub Credentials
```
DOCKER_USERNAME=tu_usuario
DOCKER_TOKEN=tu_token
DOCKER_EMAIL=tu_email@example.com
```

### Kubernetes Context
```
KUBE_CONTEXT=minikube  # O el contexto de tu cluster
KUBE_NAMESPACE=stage
```

## Troubleshooting

### Los pods no están iniciando
```bash
# Ver descripción detallada del pod
kubectl describe pod -n stage pod/user-service-xxxxx

# Ver logs
kubectl logs -n stage pod/user-service-xxxxx
```

### ImagePullBackOff
```bash
# Verifica que el secret existe
kubectl get secrets -n stage

# Verifica que el secret tiene las credenciales correctas
kubectl get secret dockerhub-credentials -n stage -o yaml
```

### CrashLoopBackOff
```bash
# Ver logs del contenedor
kubectl logs -n stage pod/user-service-xxxxx --previous

# Ver eventos
kubectl describe pod -n stage pod/user-service-xxxxx
```

### Config Server no responde
```bash
# Verificar que Config Server está corriendo
kubectl get pods -n stage -l app=config-server

# Verificar logs
kubectl logs -n stage -l app=config-server

# Verificar configuración
kubectl get configmap -n stage config-server-repo -o yaml
```

### Zipkin no recibe traces
```bash
# Verificar que Zipkin está corriendo
kubectl get pods -n stage -l app=zipkin

# Verificar conectividad desde un pod
kubectl exec -it -n stage pod/user-service-xxxxx -- curl http://zipkin:9411/health
```

## Limpieza

### Eliminar todo del namespace
```bash
kubectl delete all -n stage
```

### Eliminar el namespace completo
```bash
kubectl delete namespace stage
```

### Eliminar solo un servicio
```bash
kubectl delete -f k8s/stage/user-service/
```

## Notas Importantes

1. **Base de Datos**: Los servicios usan H2 en memoria. Los datos se pierden al reiniciar los pods.

2. **Configurable**: Puedes editar los ConfigMaps para cambiar la configuración:
   ```bash
   kubectl edit configmap user-service-config -n stage
   ```

3. **Escalabilidad**: Para escalar un servicio:
   ```bash
   kubectl scale deployment user-service -n stage --replicas=3
   ```

4. **Actualizaciones**: Para actualizar una imagen:
   ```bash
   kubectl set image deployment/user-service \
     user-service=merako34/user-service:0.2.0 \
     -n stage
   ```

## Recursos Útiles

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Spring Cloud Config Server](https://spring.io/projects/spring-cloud-config)
- [Zipkin Documentation](https://zipkin.io/)
- [Spring Cloud Netflix Eureka](https://spring.io/projects/spring-cloud-netflix)

## Support

Para más información o problemas, consulta:
- README.md principal del proyecto
- setup/kubernetes.md
- setup/config_setup.md
