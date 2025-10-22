# Guía de Configuración de Credenciales - Jenkins y Kubernetes

## PASO 1: Crear secretos de Docker Hub en stage y prod

### 1.1 Para namespace STAGE

Ejecuta en PowerShell:
```powershell
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=merako34 --docker-password=TU_TOKEN --docker-email=santiago.angel.or12@gmail.com --namespace=stage
```

Reemplaza `TU_TOKEN` con tu token real de Docker Hub.

### 1.2 Para namespace PROD

Ejecuta en PowerShell:
```powershell
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=merako34 --docker-password=TU_TOKEN --docker-email=santiago.angel.or12@gmail.com --namespace=prod
```

### 1.3 Verificar que se crearon todos

```powershell
kubectl get secrets -n dev
kubectl get secrets -n stage
kubectl get secrets -n prod
```

Debe mostrar en los tres: `dockerhub-credentials`

---

## PASO 2: Verificar acceso a Docker Hub desde PowerShell

```powershell
docker login -u merako34
```

Te pedirá que ingreses tu token. Pégalo y presiona Enter.

Debe mostrar: `Login Succeeded`

---

## PASO 3: Crear archivo de variables de entorno

En la raíz de tu repositorio, crea un archivo llamado `env.config` con este contenido:

```
# Configuración de Credenciales
# Archivo: env.config
# NO subir a Git (agregar a .gitignore)

# Docker Hub
DOCKER_USERNAME=merako34
DOCKER_REGISTRY=docker.io

# Kubernetes
KUBE_CONTEXT=minikube
KUBE_NAMESPACE_DEV=dev
KUBE_NAMESPACE_STAGE=stage
KUBE_NAMESPACE_PROD=prod

# Jenkins
JENKINS_URL=http://localhost:8080
JENKINS_USER=admin

# Minikube
MINIKUBE_DRIVER=docker
MINIKUBE_CPUS=4
MINIKUBE_MEMORY=8192
MINIKUBE_VERSION=v1.28.0
```

---

## PASO 4: Agregar env.config a .gitignore

En tu repositorio, abre o crea el archivo `.gitignore` y agrega:

```
# Archivos de configuración sensible
env.config
.env
.env.local
*.credentials
~/.docker-credentials/
```

---

## PASO 5: Configurar credenciales en Jenkins

### 5.1 Acceder a Jenkins

Abre en tu navegador:
```
http://localhost:8080
```

Inicia sesión con:
- Usuario: admin
- Contraseña: admin123 (o la que configuraste)

### 5.2 Ir a Manage Credentials

1. Click en "Manage Jenkins" (o "Administrar Jenkins")
2. Busca y click en "Manage Credentials" (o "Administrar credenciales")

### 5.3 Agregar credencial global

1. En el lado izquierdo, click en "global" (bajo "Stores scoped to Jenkins")
2. Click en "Add Credentials" (botón azul, lado derecho)

### 5.4 Llenar los datos

En el formulario que aparece:

- **Kind**: Selecciona "Username with password"
- **Scope**: Selecciona "Global"
- **Username**: `merako34`
- **Password**: Pega tu token de Docker Hub
- **ID**: `dockerhub-credentials` (importante, debe ser este nombre exacto)
- **Description**: `Docker Hub Credentials for microservices`

Click en "Create"

Debe mostrar: "Credencial 'dockerhub-credentials' creada exitosamente"

---

## PASO 6: Configurar acceso a Kubernetes en Jenkins

### 6.1 Crear credencial de Kubernetes

1. En Jenkins, ve a "Manage Credentials" → "global"
2. Click "Add Credentials"

En el formulario:

- **Kind**: Selecciona "Kubernetes configuration (kubeconfig)"
- **Scope**: "Global"
- **Kubeconfig**: Selecciona "Enter directly"

### 6.2 Obtener el kubeconfig

En PowerShell, ejecuta:
```powershell
kubectl config view --raw
```

Copia TODA la salida (todo lo que aparezca).

### 6.3 Pegar en Jenkins

Pega el contenido copiado en el campo "Kubeconfig" de Jenkins.

- **ID**: `kubernetes-config` (importante, debe ser este nombre exacto)
- **Description**: `Kubeconfig for Minikube`

Click "Create"

---

## PASO 7: Verificar que todo está configurado

### 7.1 Verificar secretos en Kubernetes

```powershell
kubectl get secrets --all-namespaces | grep dockerhub-credentials
```

Debe mostrar 3 líneas (una por cada namespace).

### 7.2 Verificar acceso a Docker Hub

```powershell
docker info | Select-String "Username"
```

Debe mostrar tu usuario logueado.

### 7.3 Verificar Jenkins

1. Abre http://localhost:8080
2. Manage Jenkins → Manage Credentials → global
3. Debe aparecer:
   - `dockerhub-credentials` (Username with password)
   - `kubernetes-config` (Kubeconfig)

---

## Resumen de lo configurado

✓ Secretos de Docker Hub en todos los namespaces (dev, stage, prod)
✓ Archivo de variables de entorno (env.config)
✓ Credenciales de Docker Hub en Jenkins
✓ Acceso a Kubernetes configurado en Jenkins

---

## Próximos pasos

1. Crear Jenkinsfiles para los microservicios
2. Crear pipelines en Jenkins
3. Crear manifiestos de Kubernetes para los deployments
4. Configurar los tests (unitarias, integración, E2E, rendimiento)

---

## Troubleshooting

### Si Docker login falla
```powershell
docker logout
docker login -u merako34
```

### Si kubectl no encuentra los secretos
```powershell
kubectl get secrets -n dev
kubectl describe secret dockerhub-credentials -n dev
```

### Si Jenkins no está accesible
Verifica que Docker Desktop esté corriendo y el contenedor de Jenkins esté activo:
```powershell
docker ps | Select-String jenkins
```

### Si necesitas recrear un secreto
```powershell
kubectl delete secret dockerhub-credentials -n dev
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=merako34 --docker-password=TU_TOKEN --docker-email=santiago.angel.or12@gmail.com --namespace=dev
```