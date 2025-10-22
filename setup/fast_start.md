# Comandos para Apagar y Levantar Servicios

## APAGAR (sin borrar datos)

### 1. Apagar Minikube (guarda todos los datos)

```powershell
minikube stop
```

Esto detiene el cluster pero mantiene:
- ✓ Namespaces
- ✓ Secretos
- ✓ Configuración
- ✓ Todos los datos

### 2. Apagar Jenkins

```powershell
docker stop jenkins-controller
```

O si usas docker-compose:

```powershell
docker-compose stop
```

### 3. Apagar Docker Desktop

Cierra Docker Desktop normalmente (click en X o File → Exit).

---

## LEVANTAR DE NUEVO

### Paso 1: Iniciar Docker Desktop

Abre Docker Desktop normalmente desde el menú de inicio o desde:
```
C:\Program Files\Docker\Docker\Docker Desktop.exe
```

Espera a que esté completamente listo (verificas en la bandeja del sistema).

### Paso 2: Levantar Minikube

```powershell
minikube start
```

Espera a que termine (tomará 1-2 minutos).

Verifica que esté listo:
```powershell
minikube status
```

Debe mostrar:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Paso 3: Levantar Jenkins

```powershell
docker start jenkins-controller
```

O si usas docker-compose:

```powershell
docker-compose up -d
```

Espera 30-60 segundos a que Jenkins inicie completamente.

### Paso 4: Verificar que todo está corriendo

```powershell
# Ver que Minikube está activo
minikube status

# Ver que Jenkins está corriendo
docker ps | Select-String jenkins

# Ver que los secretos siguen ahí
kubectl get secrets --all-namespaces | Select-String "dockerhub"

# Ver los namespaces
kubectl get namespaces
```

---

## Resumen rápido

### APAGAR (sin borrar)
```powershell
minikube stop
docker stop jenkins-controller
# Cierra Docker Desktop
```

### LEVANTAR DE NUEVO
```powershell
# 1. Abre Docker Desktop
# 2. Espera a que esté listo
# 3. Ejecuta:
minikube start
docker start jenkins-controller
```

---

## Comandos útiles después de levantar

```powershell
# Ver estado general
minikube status

# Ver que Jenkins está listo
docker logs jenkins-controller | tail -20

# Acceder a Jenkins
# http://localhost:8080

# Ver pods en Kubernetes
kubectl get pods -A

# Ver si tus secretos siguen ahí
kubectl get secrets --all-namespaces | Select-String "dockerhub"
```

---

## Importante

- **NO ejecutes `minikube delete`** - Eso SÍ borra todo
- **NO ejecutes `docker rm jenkins-controller`** - Eso SÍ borra el contenedor
- Solo usa `minikube stop` y `docker stop` para pausar sin perder datos

---

## Si algo falla al levantar

### Minikube no inicia

```powershell
# Ver logs
minikube logs

# O reinicia completamente
minikube delete --all
minikube start --driver=docker --cpus=2 --memory=4096
```

### Jenkins no inicia

```powershell
# Ver logs
docker logs jenkins-controller

# O reinicia
docker restart jenkins-controller
```

### Docker no inicia

- Abre Docker Desktop manualmente
- Espera a que aparezca "Docker is running" en la bandeja del sistema
- Luego intenta de nuevo con los otros comandos