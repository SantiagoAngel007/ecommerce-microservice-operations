# Configurar Jenkins en Docker

Guía completa para levantar Jenkins 2.479.1 con soporte para Kubernetes y microservicios.

## Requisitos Previos

- Docker Desktop instalado y corriendo
- PowerShell (Windows) o Terminal (Linux/Mac)
- Mínimo 2GB RAM disponible
- Puerto 8080 disponible

## Estructura de Directorios

```
proyecto/
├── jenkins/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── plugins.txt
│   └── init.groovy.d/          (se crea automáticamente)
├── kubernetes/
└── setup/
```

## Paso 1: Crear Dockerfile

Crea el archivo `jenkins/Dockerfile` con el contenido:

```dockerfile
FROM jenkins/jenkins:2.479.1-lts-jdk17

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    maven \
    jq \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    usermod -aG docker jenkins

RUN curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN mkdir -p /var/jenkins_home/.kube && \
    mkdir -p /var/jenkins_home/.docker && \
    mkdir -p /var/jenkins_home/.ssh && \
    chown -R jenkins:jenkins /var/jenkins_home

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt 2>&1 | grep -i "failed" || true

ENV JAVA_OPTS="-Xmx1024m -Xms512m"

USER jenkins

EXPOSE 8080 50000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080 || exit 1
```

## Paso 2: Crear docker-compose.yml

Crea el archivo `jenkins/docker-compose.yml`:

```yaml
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: jenkins-controller
    restart: unless-stopped
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Xmx1024m -Xms512m
      - DOCKER_HOST=unix:///var/run/docker.sock
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

volumes:
  jenkins_home:
    driver: local
```

## Paso 3: Crear plugins.txt

Crea el archivo `jenkins/plugins.txt` con los plugins necesarios:

```
git:5.3.2
github:1.38.1
docker-workflow:580.v87c7fc1639ac
kubernetes:1.34.1
kubernetes-cli:1.15.0
maven-plugin:3.24
workflow-aggregator:600.v7ee835e57347
credentials:1336.v1e07e7c4f1d2
junit:1290.v2163efab_a_d1
```

## Paso 4: Construir la Imagen

Abre PowerShell o Terminal y ejecuta:

```powershell
# Navega a la carpeta jenkins
cd jenkins

# Limpia contenedores e imágenes anteriores
docker-compose down -v
docker system prune -f

# Construye la imagen (tarda 15-20 minutos)
docker-compose build --no-cache
```

## Paso 5: Levantar Jenkins

```powershell
# Inicia el contenedor
docker-compose up -d

# Verifica los logs
docker logs jenkins-controller -f
```

Espera a ver el mensaje:
```
Jenkins is fully up and running
```

## Paso 6: Obtener Contraseña Inicial

En otra ventana de PowerShell, obtén la contraseña inicial:

```powershell
docker exec jenkins-controller cat /var/jenkins_home/secrets/initialAdminPassword
```

Copia la contraseña que aparece.

## Paso 7: Acceder a Jenkins

Abre tu navegador en:

```
http://localhost:8080
```

1. Pega la contraseña inicial
2. Click en **Continue**
3. Selecciona **Install suggested plugins** (o elige personalizados)
4. Crea tu usuario admin
5. Completa la configuración inicial

## Paso 8: Instalar Plugins Adicionales (Opcional)

Si necesitas plugins adicionales después:

1. Ve a **Manage Jenkins** → **Plugins** → **Available plugins**
2. Busca e instala:
   - HTML Publisher
   - Workspace Cleanup
   - Timestamper
   - Performance
   - SonarQube Scanner

## Comandos Útiles

```powershell
# Ver logs en tiempo real
docker logs jenkins-controller -f

# Detener Jenkins
docker-compose stop

# Reiniciar Jenkins
docker-compose restart

# Eliminar Jenkins completamente (cuidado)
docker-compose down -v

# Acceder a la consola del contenedor
docker exec -it jenkins-controller bash

# Ver estado del contenedor
docker ps | grep jenkins

# Ver volúmenes
docker volume ls | grep jenkins
```

## Solución de Problemas

### Jenkins no inicia
```powershell
# Verifica los logs
docker logs jenkins-controller

# Limpia e intenta de nuevo
docker-compose down -v
docker system prune -f
docker-compose build --no-cache
docker-compose up -d
```

### Puerto 8080 ya está en uso
```powershell
# Cambia el puerto en docker-compose.yml
ports:
  - "8081:8080"    # Usa puerto 8081

# Luego accede a http://localhost:8081
```

### Problemas con plugins
```powershell
# Reinstala sin los plugins problemáticos
docker-compose down -v
# Edita plugins.txt y comenta la línea problemática
docker-compose build --no-cache
docker-compose up -d
```

## Configuración de Credenciales Docker Hub

Para poder hacer push de imágenes a Docker Hub:

1. En Jenkins, ve a **Manage Jenkins** → **Credentials**
2. Click en **Add Credentials**
3. Selecciona **Username with password**
4. Ingresa:
   - Username: tu usuario de Docker Hub
   - Password: tu token de Docker Hub
   - ID: `dockerhub-credentials`

## Ambiente Variables

Para el taller, asegúrate de tener configuradas en Jenkins:

- `DOCKER_REGISTRY`: `docker.io`
- `DOCKER_USERNAME`: tu usuario
- `KUBE_CONTEXT`: `minikube` (si usas Minikube)
- `KUBE_NAMESPACE`: `dev`, `stage`, o `prod`

## Información de Acceso

```
URL:      http://localhost:8080
Usuario:  (el que creaste)
Contraseña: (la que configuraste)
```


## Referencias

- [Documentación oficial de Jenkins](https://www.jenkins.io/doc/)
- [Docker Hub Jenkins](https://hub.docker.com/r/jenkins/jenkins)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)