# Guía de Configuración Manual de Minikube

## Requisitos previos

Asegúrate de tener instalado:
- Minikube: `C:\Program Files\Kubernetes\Minikube\minikube.exe`
- kubectl
- Docker Desktop
- PowerShell

## PASO 1: Limpiar cluster anterior (si existe)

```powershell
minikube delete --all
```

---

## PASO 2: Iniciar Minikube

```powershell
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=4g --kubernetes-version=v1.28.0
```

**Nota:** Si recibis error de memoria insuficiente, usa:
```powershell
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=4g --kubernetes-version=v1.28.0
```

Espera a que termine. Mensaje esperado:
```
Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

---

## PASO 3: Habilitar addons necesarios

```powershell
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server
minikube addons enable registry
```

---

## PASO 4: Configurar contexto de kubectl

```powershell
kubectl config use-context minikube
```

---

## PASO 5: Esperar a que el cluster esté listo

```powershell
kubectl get nodes
```

Debe mostrar:
```
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   2m    v1.28.0
```

Si muestra "NotReady", espera 30 segundos y repite.

---

## PASO 6: Crear namespaces

```powershell
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod
```

Verificar que se crearon:
```powershell
kubectl get namespaces
```

---

## PASO 7: Crear secretos de Docker Hub

Antes de ejecutar, obtén tus credenciales:
1. Ve a: https://hub.docker.com/settings/security
2. Click en "New Access Token"
3. Copia el token generado

**Para namespace dev:**
```powershell
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=TU_USUARIO --docker-password=TU_TOKEN --docker-email=TU_EMAIL --namespace=dev
```

**Para namespace stage:**
```powershell
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=TU_USUARIO --docker-password=TU_TOKEN --docker-email=TU_EMAIL --namespace=stage
```

**Para namespace prod:**
```powershell
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=TU_USUARIO --docker-password=TU_TOKEN --docker-email=TU_EMAIL --namespace=prod
```

Reemplaza:
- `TU_USUARIO` con tu usuario de Docker Hub
- `TU_TOKEN` con tu token de acceso
- `TU_EMAIL` con tu email de Docker Hub

---

## PASO 8: Verificar configuración final

```powershell
kubectl get nodes
kubectl get namespaces
kubectl get secrets -n dev
kubectl get secrets -n stage
kubectl get secrets -n prod
```

---

# COMANDOS ÚTILES

## Ver estado del cluster

```powershell
minikube status
```

## Obtener IP de Minikube

```powershell
minikube ip
```

## Ver información del cluster

```powershell
kubectl cluster-info
```

## Ver eventos del cluster

```powershell
kubectl get events -A
```

---

## Dashboard (Interfaz gráfica)

Abre el dashboard en tu navegador:
```powershell
minikube dashboard
```

Se abrirá automáticamente en: http://127.0.0.1:PORT

---

## Ver logs de Minikube

```powershell
minikube logs
```

## Ver logs en tiempo real

```powershell
minikube logs --follow
```

---

## Acceder a la máquina virtual de Minikube

```powershell
minikube ssh
```

---

## Usar Docker con Minikube

En PowerShell:
```powershell
minikube docker-env | Invoke-Expression
```

En bash:
```bash
eval $(minikube docker-env)
```

Después puedes usar `docker` directamente con las imágenes de Minikube.

---

## Detener el cluster (sin eliminar datos)

```powershell
minikube stop
```

## Reiniciar el cluster

```powershell
minikube start
```

## Eliminar el cluster completamente

```powershell
minikube delete
```

---

# COMANDOS DE KUBECTL ÚTILES

## Ver todos los pods en todos los namespaces

```powershell
kubectl get pods -A
```

## Ver pods en un namespace específico

```powershell
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod
```

## Ver servicios

```powershell
kubectl get services -A
kubectl get services -n dev
```

## Ver deployments

```powershell
kubectl get deployments -A
kubectl get deployments -n dev
```

## Ver secretos

```powershell
kubectl get secrets -n dev
kubectl get secrets -n stage
kubectl get secrets -n prod
```

## Describir un secreto

```powershell
kubectl describe secret dockerhub-credentials -n dev
```

## Ver detalles de un pod

```powershell
kubectl describe pod POD_NAME -n dev
```

## Ver logs de un pod

```powershell
kubectl logs POD_NAME -n dev
```

## Ver logs en tiempo real

```powershell
kubectl logs -f POD_NAME -n dev
```

## Ejecutar un comando en un pod

```powershell
kubectl exec -it POD_NAME -n dev -- /bin/bash
```

## Ejecutar un pod de prueba

```powershell
kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh
```

## Obtener información de uso de recursos

```powershell
kubectl top nodes
kubectl top pods -A
kubectl top pods -n dev
```

## Ver eventos

```powershell
kubectl get events -n dev
```

## Eliminar un pod

```powershell
kubectl delete pod POD_NAME -n dev
```

## Eliminar todos los pods en un namespace

```powershell
kubectl delete pods --all -n dev
```

---

# SOLUCIÓN DE PROBLEMAS

## Si Minikube no inicia

Limpia y reinicia:
```powershell
minikube delete --all
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=4g --kubernetes-version=v1.28.0
```

## Si kubectl no reconoce Minikube

Configura el contexto:
```powershell
kubectl config use-context minikube
```

## Si Docker no está disponible

Asegúrate de que Docker Desktop esté corriendo y reinicia PowerShell.

## Si tienes problemas de memoria

Reduce la memoria asignada a Minikube:
```powershell
minikube stop
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=4g --kubernetes-version=v1.28.0
```

O aumenta la RAM en Docker Desktop:
- Abre Docker Desktop
- Settings → Resources → Memory (aumenta a 10GB o más)
- Apply & Restart

## Si los secretos no se crean correctamente

Verifica que el namespace existe:
```powershell
kubectl get namespace dev
```

Elimina y recrea:
```powershell
kubectl delete secret dockerhub-credentials -n dev
kubectl create secret docker-registry dockerhub-credentials --docker-server=docker.io --docker-username=TU_USUARIO --docker-password=TU_TOKEN --docker-email=TU_EMAIL --namespace=dev
```

---

# VERIFICACIÓN FINAL

Una vez completado todo, ejecuta:

```powershell
# Ver estado general
minikube status

# Ver nodos
kubectl get nodes

# Ver namespaces
kubectl get namespaces

# Ver secretos en cada namespace
kubectl get secrets -n dev
kubectl get secrets -n stage
kubectl get secrets -n prod

# Ver addons habilitados
minikube addons list
```

Si todo muestra información sin errores, tu Minikube está listo para el taller.

