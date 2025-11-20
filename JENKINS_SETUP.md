# Guía: Configuración de Jenkins y CI/CD

## 🎯 Opciones

Hay dos formas de usar Jenkins:

1. **Opción A (Local)**: Levantar Jenkins en Docker en tu máquina
2. **Opción B (Compartido)**: Usar una instancia de Jenkins en línea compartida por el equipo

---

## Opción A: Jenkins en Docker (Local)

### Prerequisitos

- Docker instalado
- 4GB RAM disponible
- Puerto 8080 disponible

### 1. Estructura

```
jenkins/
├── Dockerfile              # Configuración de Jenkins
├── jenkins_home/           # Volumen (NO subir a git)
├── init.groovy.d/
│   ├── basic-security.groovy
│   └── configure-docker.groovy
└── docker-compose.yml      # (Opcional) para facilitar levantamiento
```

### 2. Levantamiento Rápido con Docker

```bash
# Posicionarse en la carpeta
cd jenkins

# Construir imagen
docker build -t jenkins-custom .

# Ejecutar contenedor
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-custom

# Verificar que está corriendo
docker ps | grep jenkins

# Ver logs
docker logs -f jenkins
```

### 3. Levantamiento con Docker Compose (Recomendado)

```bash
# Crear docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    build: .
    container_name: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Xmx2g
    networks:
      - jenkins-network

volumes:
  jenkins_home:

networks:
  jenkins_network:
EOF

# Levantar
docker-compose up -d

# Ver logs
docker-compose logs -f jenkins
```

### 4. Acceder a Jenkins

```
URL: http://localhost:8080
Usuario: admin
Contraseña: admin123
```

### 5. Configuración Inicial

```
1. Ir a http://localhost:8080
2. Ingresar con admin/admin123
3. Ir a Dashboard → Manage Jenkins → Configure System
4. Ir a Dashboard → Manage Jenkins → Manage Credentials
5. Agregar credenciales para:
   - GitHub (Personal Access Token)
   - GCP (archivo gcp-key.json)
   - Docker Hub (usuario y password)
```

### 6. Detener Jenkins

```bash
# Con Docker Compose
docker-compose down

# Con Docker
docker stop jenkins
docker rm jenkins
```

---

## Opción B: Jenkins en Línea (Compartido)

Esta opción es útil para que todo el equipo use la misma instancia de Jenkins.

### Plataformas Recomendadas

#### 1. **Jenkins en Google Cloud (Recomendado para este proyecto)**

```bash
# Crear una VM en GCP
gcloud compute instances create jenkins-server \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --scopes=cloud-platform

# Conectarse y instalar Jenkins
gcloud compute ssh jenkins-server --zone=us-central1-a

# En la VM:
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
echo "deb https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Obtener contraseña inicial
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Acceder en: http://<IP-JENKINS>:8080
```

#### 2. **Jenkins.io Cloud (Jenkins Hosted)**

```
https://app.jenkins.io/
- Crear cuenta gratuita
- Crear nueva instancia
- Todos los miembros del equipo acceden a la misma URL
```

#### 3. **CloudBees (Solución Empresarial)**

```
https://www.cloudbees.com/jenkins/cloudbees-ci
- Opción más robusta y confiable
- Free tier disponible
```

### Configuración Multi-usuario

En Jenkins en línea, configurar para múltiples usuarios:

```
1. Manage Jenkins → Configure Global Security
2. Enable "Matrix-based security"
3. Agregar usuarios del equipo con permisos específicos
4. Cada usuario crea su propio token API para pipelines
```

---

## Configuración de Jenkinsfiles con GCP

### 1. Estructura de Jenkinsfiles

```
Jenkinsfile                # Pipeline principal (detecta env automáticamente)
Jenkinsfile.dev            # DEV local/minikube
Jenkinsfile.dev-gcp        # DEV con GCP/GKE
Jenkinsfile.stage-gcp      # STAGE con GCP/GKE
Jenkinsfile.prod-gcp       # PROD con GCP/GKE
Jenkinsfile.infrastructure # Terraform en GCP
```

### 2. Configurar Credenciales en Jenkins

**En Jenkins UI:**

```
1. Ir a Dashboard → Manage Jenkins → Manage Credentials
2. Agregar las siguientes credenciales:

   a) GCP Service Account
      - Tipo: "Google Container Registry credential"
      - Upload JSON key file (gcp-key.json)
      - ID: gcp-credentials

   b) GitHub Token
      - Tipo: "Username with password"
      - Username: tu-usuario-github
      - Password: tu-github-token
      - ID: github-credentials

   c) Docker Hub (si usas registros privados)
      - Tipo: "Username with password"
      - Username: docker-usuario
      - Password: docker-token
      - ID: docker-hub-credentials
```

### 3. Variables de Entorno en Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        GCP_PROJECT_ID = 'ecommerce-microservices-478116'
        GCP_REGION = 'us-central1'
        GCP_ZONE = 'us-central1-a'
        GCP_CREDENTIALS = credentials('gcp-credentials')
        DOCKER_REGISTRY = 'us-central1-docker.pkg.dev'
        KUBECONFIG = "${WORKSPACE}/kubeconfig"
    }

    stages {
        stage('Setup GCP') {
            steps {
                script {
                    // Autenticarse en GCP
                    sh '''
                        gcloud auth activate-service-account \
                            --key-file=${GCP_CREDENTIALS}
                        gcloud config set project ${GCP_PROJECT_ID}
                        gcloud container clusters get-credentials ecommerce-dev-cluster \
                            --zone ${GCP_ZONE}
                    '''
                }
            }
        }
    }
}
```

### 4. Crear una Pipeline en Jenkins

```
1. Dashboard → New Item
2. Nombre: "ecommerce-dev-build"
3. Tipo: "Pipeline"
4. En "Pipeline" → "Definition": "Pipeline script from SCM"
5. SCM: Git
   - Repository URL: https://github.com/tu-usuario/ecommerce-microservice-operations
   - Branch: */main
   - Script Path: Jenkinsfile.dev-gcp
6. Guardar
7. Build Now
```

### 5. Configurar Webhook de GitHub (Trigger Automático)

```
En GitHub:
1. Settings → Webhooks → Add webhook
2. Payload URL: http://<jenkins-url>:8080/github-webhook/
3. Content type: application/json
4. Trigger: "Just the push event"
5. Active: ✓

En Jenkins:
1. Pipeline → Build Triggers
2. Check: "GitHub hook trigger for GITScm polling"
3. Guardar
```

---

## 🔑 Credenciales Necesarias

| Credencial | Tipo | Dónde Obtener |
|-----------|------|---------------|
| GCP Service Account | JSON | GCP Console → IAM & Admin → Service Accounts |
| GitHub Token | Personal Access Token | GitHub → Settings → Developer settings → Tokens |
| Docker Hub | Username + Token | Docker Hub → Account Settings → Security |

---

## ✅ Checklist

- [ ] Jenkins está running (Docker o Cloud)
- [ ] Acceso a http://localhost:8080 (si es Docker)
- [ ] Credenciales GCP configuradas
- [ ] Credenciales GitHub configuradas
- [ ] Jenkinsfile.dev-gcp existe
- [ ] Pipeline creada en Jenkins
- [ ] Webhook de GitHub configurado
- [ ] Build manual ejecutado exitosamente

---

## 📝 Notas Importantes

- **Jenkins en Docker**: Ideal para desarrollo local
- **Jenkins en línea**: Mejor para equipo compartido
- Los Jenkinsfiles automáticamente usan las credenciales configuradas
- Cada pipeline debe estar asociada a un Jenkinsfile específico
- Los logs de pipelines están en la interfaz de Jenkins

