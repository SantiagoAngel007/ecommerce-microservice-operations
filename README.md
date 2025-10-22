# ecommerce-microservice-operations

Repositorio de infraestructura y operaciones para el sistema de microservicios de e-commerce. Este proyecto contiene toda la configuración necesaria para ejecutar, probar y desplegar la aplicación en diferentes ambientes (desarrollo, staging y producción).

## Descripción General

Este repositorio forma parte del **Taller 2: Pruebas y Lanzamiento** y se encarga de:

- **Configuración de infraestructura**: Kubernetes (Minikube), Docker, Jenkins
- **Pipelines CI/CD**: Construcción, pruebas y despliegue automatizado
- **Gestión de ambientes**: Desarrollo, staging y producción
- **Credenciales y secretos**: Configuración segura de acceso a registros y servicios
- **Automatización**: Scripts para iniciar/detener servicios sin perder datos

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
├── kubernetes/                       # Manifiestos de Kubernetes
│   ├── kubernetes.md                # Documentación de deployments
│   └── [manifiestos por microservicio]
│
├── terraform/                        # Infraestructura como código (IaC)
│   └── terraform.md                 # Documentación de recursos
│
├── setup/                            # Guías y scripts de configuración
│   ├── minikube_setup.md            # Guía completa de Minikube
│   ├── Jenkins_setup.md             # Instalación y configuración de Jenkins
│   ├── config_setup.md              # Configuración de credenciales
│   ├── fast_start.md                # Comandos para apagar/levantar servicios
│   └── credentials-setup.ps1        # Script de automatización
│
├── docker/                           # Configuración Docker general
│   └── docker.md                    # Documentación de Docker
│
├── docs/                             # Documentación general
│   └── docs.md                       # Archivos de documentación
│
├── env.config                        # Variables de entorno (NO subir a Git)
├── .gitignore                        # Archivos a ignorar en Git
└── README.md                         # Este archivo

```

## Requisitos Previos

- **Windows 11 / macOS / Linux**
- **Docker Desktop** (versión reciente)
- **Minikube** (v1.28.0 o superior)
- **kubectl** (v1.28.0 o superior)
- **PowerShell** (en Windows) o bash (en Linux/macOS)
- **Git**
- **8GB de RAM mínimo** (para Docker + Minikube)
- **Cuenta en Docker Hub** (para push de imágenes)

## Instalación Rápida

### 1. Clonar el repositorio

```bash
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git
git clone https://github.com/[tu-usuario]/ecommerce-microservice-operations.git
cd ecommerce-microservice-operations
```

### 2. Configurar Minikube

```powershell
# Ejecutar todos los pasos en setup/minikube_setup.md
# O ejecutar manualmente:

minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=4g
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod
```

Ver: [`setup/minikube_setup.md`](setup/minikube_setup.md)

### 3. Levantar Jenkins

```powershell
cd jenkins
docker-compose build --no-cache
docker-compose up -d
```

Ver: [`setup/Jenkins_setup.md`](setup/Jenkins_setup.md)

### 4. Configurar Credenciales

```powershell
# Crear secretos en Kubernetes y Jenkins
# Ver: setup/config_setup.md

kubectl create secret docker-registry dockerhub-credentials \
    --docker-server=docker.io \
    --docker-username=TU_USUARIO \
    --docker-password=TU_TOKEN \
    --docker-email=TU_EMAIL \
    --namespace=dev
```

Ver: [`setup/config_setup.md`](setup/config_setup.md)

## Microservicios Configurados

Los siguientes 6 microservicios tienen pipelines CI/CD configurados:

1. **User Service** (8700) - Gestión de usuarios y autenticación
2. **Product Service** (8500) - Catálogo de productos
3. **Order Service** (8300) - Gestión de órdenes y carritos
4. **Payment Service** (8400) - Procesamiento de pagos
5. **Favourite Service** (8800) - Gestión de favoritos
6. **Shipping Service** (8600) - Envíos y logística

Todos los servicios se comunican entre sí a través de la malla de microservicios, permitiendo pruebas de integración completas.

## Componentes de Infraestructura

### Kubernetes (Minikube)

- **3 Namespaces**: dev, stage, prod
- **Servicios**: Zipkin (tracing), Eureka (service discovery), Config Server
- **Plugins**: ingress, dashboard, metrics-server, registry

### Jenkins

- **Base**: jenkins/jenkins:2.479.1-lts-jdk17
- **Plugins**: Git, Docker, Kubernetes, Maven, Pipeline
- **Credenciales**: Docker Hub, Kubernetes kubeconfig
- **Puertos**: 8080 (UI), 50000 (agentes)

### Docker

- **Registro**: Docker Hub (docker.io)
- **Imágenes**: Base en Spring Boot
- **Volúmenes**: Datos persistentes para Jenkins

## Pipelines CI/CD

### Estructura del Pipeline

Cada microservicio tiene 3 pipelines correspondientes a los 3 ambientes:

#### 1. Pipeline Dev (Desarrollo)
- Clonar repositorio
- Build con Maven
- Pruebas unitarias
- Construir imagen Docker
- Push a Docker Hub
- Desplegar en namespace `dev`

#### 2. Pipeline Stage (Staging)
- Todos los pasos del dev
- Pruebas de integración
- Pruebas E2E
- Desplegar en namespace `stage`

#### 3. Pipeline Master (Producción)
- Todos los pasos anteriores
- Pruebas de rendimiento/estrés con Locust
- Validación de sistema
- Generar Release Notes
- Desplegar en namespace `prod`

## Pruebas Implementadas

### Unitarias (5+ por servicio)
- Validación de componentes individuales
- Pruebas de lógica de negocio
- Tests de servicios y controladores

### Integración (5+ por servicio)
- Comunicación entre servicios
- Integración con base de datos
- APIs internas

### E2E (5+ por servicio)
- Flujos completos de usuario
- Validación de procesos de negocio
- Casos de uso reales

### Rendimiento y Estrés
- Pruebas con Locust
- Simulación de carga realista
- Métricas: tiempo de respuesta, throughput, tasa de errores

## Credenciales

### Variables de Entorno

Se requiere un archivo `env.config` (no versionado):

```bash
DOCKER_USERNAME=tu_usuario
DOCKER_TOKEN=tu_token
DOCKER_EMAIL=tu_email
JENKINS_URL=http://localhost:8080
KUBE_CONTEXT=minikube
```

### Secretos de Kubernetes

Se crean automáticamente en todos los namespaces:
- `dockerhub-credentials`: Para acceso al registro Docker Hub
- `kubernetes-config`: Kubeconfig para acceso a Kubernetes

### Jenkins Credentials

- `dockerhub-credentials`: Username + Password
- `kubernetes-config`: Kubeconfig (Secret text)

## Comandos Útiles

### Apagar (sin perder datos)

```powershell
minikube stop
docker stop jenkins-controller
```

### Levantar de nuevo

```powershell
minikube start
docker start jenkins-controller
```

### Ver estado

```powershell
minikube status
kubectl get pods -A
docker ps | Select-String jenkins
```

### Dashboard

```powershell
minikube dashboard
```

Ver más en: [`setup/fast_start.md`](setup/fast_start.md)

## Documentación

- [`setup/minikube_setup.md`](setup/minikube_setup.md) - Guía completa de Minikube
- [`setup/Jenkins_setup.md`](setup/Jenkins_setup.md) - Instalación y configuración
- [`setup/config_setup.md`](setup/config_setup.md) - Configuración de credenciales
- [`setup/fast_start.md`](setup/fast_start.md) - Comandos rápidos

## Solución de Problemas

### Minikube no inicia
```powershell
minikube delete --all
minikube start --driver=docker --cpus=2 --memory=4096
```

### Jenkins no accesible
```powershell
docker logs jenkins-controller
docker restart jenkins-controller
```

### Secretos no se crean
```powershell
kubectl get secrets -n dev
kubectl describe secret dockerhub-credentials -n dev
```

### Puerto 8080 en uso
Cambiar puerto en `jenkins/docker-compose.yml`:
```yaml
ports:
  - "8081:8080"
```

## Flujo de Trabajo

1. **Desarrollo**: Cambios en el repositorio del backend → Pipeline dev → Despliegue en dev
2. **Testing**: Ejecución de pruebas → Pipeline stage → Despliegue en stage
3. **Producción**: Validación final → Pipeline master → Despliegue en prod + Release Notes

## Reportes y Métricas

Cada pipeline genera:

- **Configuración**: Texto y pantallazos de la configuración
- **Resultados**: Ejecución exitosa con detalles
- **Análisis**: Interpretación de pruebas de rendimiento
- **Release Notes**: Documentación de versiones desplegadas

## Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `env.config` | Variables de entorno (NO versionado) |
| `.gitignore` | Archivos a ignorar |
| `jenkins/Dockerfile` | Imagen custom de Jenkins |
| `jenkins/docker-compose.yml` | Orquestación de servicios |
| `jenkins/plugins.txt` | Lista de plugins |
| `setup/*.md` | Guías de configuración |

## Buenas Prácticas

- Nunca subir `env.config`, `.docker-credentials/`, o kubeconfigs a Git
- Usar `minikube stop` en lugar de `minikube delete`
- Usar `docker stop` en lugar de `docker rm`
- Verificar logs antes de reintentar: `docker logs` o `minikube logs`
- Mantener backups de configuraciones críticas

## Changelog

### v1.0.0
- Configuración inicial de Minikube
- Setup de Jenkins con plugins
- Credenciales para Docker Hub y Kubernetes
- Guías de instalación y operación

## Soporte y Contribuciones

Para reportar problemas o sugerencias, crear un issue en el repositorio.

## Licencia

Este proyecto es parte del curso de Taller 2: Pruebas y Lanzamiento.

## Autor

Generado para el Taller 2 - Pruebas y Lanzamiento (2025)

---

**Nota**: Este repositorio es solo para operaciones e infraestructura. El código de los microservicios se encuentra en el repositorio principal: [ecommerce-microservice-backend-app](https://github.com/SelimHorri/ecommerce-microservice-backend-app/)
