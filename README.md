# ecommerce-microservice-operations

Repositorio de infraestructura y operaciones para el sistema de microservicios de e-commerce. Este proyecto contiene toda la configuración necesaria para ejecutar, probar y desplegar la aplicación en diferentes ambientes (desarrollo, staging y producción) usando **Docker Desktop con Kubernetes integrado**.

## Descripción General

Este repositorio forma parte del **Taller 2: Pruebas y Lanzamiento** y se encarga de:

- **Configuración de infraestructura**: Kubernetes (Docker Desktop), Docker, Jenkins
- **Pipelines CI/CD**: Construcción, pruebas y despliegue automatizado
- **Gestión de ambientes**: Desarrollo, staging y producción
- **Credenciales y secretos**: Configuración segura de acceso a registros y servicios
- **Automatización**: Scripts para iniciar/detener servicios sin perder datos

## Requisitos Previos

- **Windows 11 / macOS / Linux**
- **Docker Desktop** (versión reciente con Kubernetes habilitado)
- **kubectl** (v1.28.0 o superior)
- **PowerShell** (en Windows) o bash (en Linux/macOS)
- **Git**
- **8GB de RAM mínimo** (para Docker Desktop + Kubernetes)
- **Cuenta en Docker Hub** (para push de imágenes)
- **Visual Studio Code** o editor de texto (opcional)

## Estructura del Proyecto

```
ecommerce-microservice-operations/
├── jenkins/                          # Configuración de Jenkins
│   ├── Dockerfile                   # Imagen Docker de Jenkins con plugins
│   ├── docker-compose.yml           # Orquestación del contenedor Jenkins
│   ├── plugins.txt                  # Lista de plugins necesarios
│   └── init.groovy.d/               # Scripts de inicialización
│       ├── basic-security.groovy    # Configuración de seguridad
│       └── configure-docker.groovy  # Integración con Docker
│
├── k8s/                              # Manifiestos de Kubernetes
│   ├── dev/                         # Ambiente de desarrollo
│   ├── stage/                       # Ambiente de staging
│   ├── prod/                        # Ambiente de producción
│   └── namespaces/                  # Configuración de namespaces
│
├── setup/                            # Guías y scripts de configuración
│   ├── Jenkins_setup.md             # Instalación y configuración de Jenkins
│   ├── config_setup.md              # Configuración de credenciales
│   ├── fast_start.md                # Comandos para apagar/levantar servicios
│
├── docs/                             # Documentación general
│   └── Reporte_final.md             # Reportes finales
│   └── Release_notes.md
│   └── Test_results.md
│
├── env.config                        # Variables de entorno (NO subir a Git)
├── .gitignore                        # Archivos a ignorar en Git
└── README.md                         # Este archivo
```

## Instalación Rápida

### 1. Clonar el repositorio

```bash
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git
git clone https://github.com/[tu-usuario]/ecommerce-microservice-operations.git
cd ecommerce-microservice-operations
```

### 2. Habilitar Kubernetes en Docker Desktop

**Windows:**
1. Abre Docker Desktop
2. Ve a `Settings` → `Kubernetes`
3. Marca la opción `Enable Kubernetes`
4. Click en `Apply & Restart`
5. Espera a que se inicie (toma unos minutos)

**macOS:**
1. Abre Docker Desktop desde Applications
2. Haz click en el ícono de Docker en la barra superior
3. Ve a `Preferences` → `Kubernetes`
4. Marca `Enable Kubernetes`
5. Click en `Apply & Restart`

**Linux:**
```bash
# Si usas Docker Desktop en Linux, sigue los mismos pasos del ícono de Docker
# O instala Docker Desktop desde: https://docs.docker.com/desktop/install/linux-installation/
```

### 3. Verificar que Kubernetes está habilitado

```bash
kubectl version
kubectl get nodes
```

Debe mostrar un nodo con nombre `docker-desktop` y status `Ready`.

### 4. Crear namespaces

```bash
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod
```

Verificar:
```bash
kubectl get namespaces
```

### 5. Levantar Jenkins

```bash
cd jenkins
docker-compose build --no-cache
docker-compose up -d
```

Acceder a Jenkins:
```
http://localhost:8080
```

Ver detalles completos en: [`setup/Jenkins_setup.md`](setup/Jenkins_setup.md)

### 6. Configurar Credenciales de Docker Hub

```bash
# Para namespace dev
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=dev

# Para namespace stage
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=stage

# Para namespace prod
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=prod
```

Ver detalles completos en: [`setup/config_setup.md`](setup/config_setup.md)

## Microservicios Configurados

Los siguientes 6 microservicios tienen pipelines CI/CD completamente configurados:

| Servicio | Puerto | Función |
|----------|--------|---------|
| **User Service** | 8700 | Gestión de usuarios y autenticación |
| **Product Service** | 8500 | Catálogo de productos |
| **Order Service** | 8300 | Gestión de órdenes y carritos |
| **Payment Service** | 8400 | Procesamiento de pagos |
| **Favourite Service** | 8800 | Gestión de favoritos |
| **Shipping Service** | 8600 | Envíos y logística |

### Componentes de Infraestructura

Además de los microservicios, se incluyen:

- **Config Server** - Centraliza la configuración de todos los servicios
- **Eureka (Service Discovery)** - Service registry para comunicación inter-servicios
- **Zipkin** - Distributed tracing para observabilidad
- **Proxy Client (API Gateway)** - Enrutamiento de requests

## Pipelines CI/CD

### Estructura de los Pipelines

Cada microservicio tiene 3 pipelines correspondientes a los 3 ambientes:

#### Pipeline DEV (Desarrollo)
- Clonar repositorio
- Build con Maven
- Construir imagen Docker
- Push a Docker Hub
- Desplegar en namespace `dev`
- **Tiempo**: ~5 min

#### Pipeline STAGE (Staging)
- Todos los pasos del dev
- Pruebas unitarias
- Pruebas de integración
- Pruebas de rendimiento
- Desplegar en namespace `stage`
- **Tiempo**: ~11 min

#### Pipeline PROD (Producción)
- Validación de cambios
- Construcción y pruebas completas
- Push a Docker Hub
- Despliegue en namespace `prod`
- Generación automática de Release Notes
- **Tiempo**: ~10 min

## Componentes de Infraestructura

### Docker Desktop Kubernetes

- **3 Namespaces**: dev, stage, prod
- **Contexto**: docker-desktop (por defecto)
- **Ventajas sobre Minikube**:
  - ✅ Más ligero y rápido
  - ✅ Integrado directamente en Docker Desktop
  - ✅ Mejor rendimiento
  - ✅ Actualización automática
  - ✅ Sin necesidad de comando `minikube start`

### Jenkins

- **Base**: jenkins/jenkins:2.479.1-lts-jdk17
- **Plugins**: Git, Docker, Kubernetes, Maven, Pipeline
- **Credenciales**: Docker Hub, Kubernetes kubeconfig
- **Puertos**: 8080 (UI), 50000 (agentes)

### Docker

- **Registro**: Docker Hub (docker.io)
- **Imágenes**: Base en Spring Boot
- **Volúmenes**: Datos persistentes para Jenkins

## Comandos Útiles

### Verificar estado de Kubernetes

```bash
# Ver nodos
kubectl get nodes

# Ver namespaces
kubectl get namespaces

# Ver contexto actual
kubectl config current-context

# Cambiar namespace por defecto
kubectl config set-context --current --namespace=dev
```

### Gestionar pods y servicios

```bash
# Ver todos los pods en un namespace
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod

# Ver servicios
kubectl get services -n dev

# Ver logs de un pod
kubectl logs <pod-name> -n dev

# Acceder a un pod
kubectl exec -it <pod-name> -n dev -- /bin/bash

# Borrar un namespace (cuidado: elimina todo dentro)
kubectl delete namespace dev
```

### Port forwarding para acceder a servicios localmente

```bash
# Acceder a un servicio específico
kubectl port-forward -n dev svc/user-service 8700:8700
kubectl port-forward -n dev svc/product-service 8500:8500
kubectl port-forward -n dev svc/proxy-client 8200:8200

# Acceder a Zipkin (tracing)
kubectl port-forward -n dev svc/zipkin 9411:9411
```

### Gestionar Jenkins

```bash
# Ver logs de Jenkins
docker logs jenkins

# Reiniciar Jenkins
docker-compose -f jenkins/docker-compose.yml restart

# Parar Jenkins
docker-compose -f jenkins/docker-compose.yml stop

# Iniciar Jenkins
docker-compose -f jenkins/docker-compose.yml up -d
```

## Troubleshooting

### Kubernetes no está habilitado

**Error**: `unable to connect to the server: dial tcp 127.0.0.1:6443: connect: connection refused`

**Solución**:
1. Abre Docker Desktop
2. Ve a `Settings` → `Kubernetes`
3. Asegúrate de que `Enable Kubernetes` esté marcado
4. Click en `Apply & Restart`

### Pods no logran descargar imágenes

**Error**: `ImagePullBackOff` o `ErrImagePull`

**Solución**:
```bash
# Verifica que el secret de Docker Hub existe
kubectl get secrets -n dev

# Si no existe, créalo
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=dev
```

### Jenkins no se conecta a Kubernetes

**Error**: `Unable to connect to Kubernetes server`

**Solución**:
1. Verifica que `kubectl` esté funcionando: `kubectl version`
2. Configura la credencial de Kubernetes en Jenkins con el archivo kubeconfig
3. Ubicación típica: `~/.kube/config` en Windows/Mac/Linux

## Reportes y Métricas

Cada pipeline genera:

- **Configuración**: Texto y pantallazos de la configuración
- **Resultados**: Ejecución exitosa con detalles
- **Análisis**: Interpretación de pruebas de rendimiento
- **Release Notes**: Documentación de versiones desplegadas

## Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| Microservicios Configurados | 6 |
| Namespaces | 3 (dev, stage, prod) |
| Pipelines | 3 (dev, stage, master) |
| Pruebas Unitarias | ✅ Implementadas |
| Pruebas de Integración | ✅ Implementadas |
| Pruebas de Rendimiento | ✅ Implementadas |
| Tasa de Éxito | 83.33% |
