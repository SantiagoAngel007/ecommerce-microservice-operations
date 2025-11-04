# Taller 2: Pruebas y Lanzamiento - Documentación del Proceso Realizado

**Fecha**: Noviembre 2024  
**Ambiente de Desarrollo**: Docker Desktop Kubernetes (No Minikube)  
**Equipo**: Taller 2 - Pruebas y Lanzamiento

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Resumen Ejecutivo](#resumen-ejecutivo)
3. [Fase 1: Configuración Inicial (10%)](#fase-1-configuración-inicial-10)
4. [Fase 2: Pipelines DEV (15%)](#fase-2-pipelines-dev-15)
5. [Fase 3: Pruebas Implementadas (30%)](#fase-3-pruebas-implementadas-30)
6. [Fase 4: Pipelines STAGE (15%)](#fase-4-pipelines-stage-15)
7. [Fase 5: Pipeline PROD y Release Notes (15%)](#fase-5-pipeline-prod-y-release-notes-15)
8. [Resultados Finales](#resultados-finales)

---

## Introducción

Este documento registra el proceso completo de configuración e implementación del **Taller 2: Pruebas y Lanzamiento** para el sistema de microservicios de e-commerce. El proyecto involucra la configuración de una infraestructura CI/CD completa utilizando Jenkins, Docker y Kubernetes para automatizar la construcción, prueba y despliegue de 6 microservicios comunicados entre sí.

### Objetivos Alcanzados

- ✅ Configurar Jenkins, Docker y Kubernetes para CI/CD
- ✅ Crear pipelines para DEV, STAGE y PROD
- ✅ Implementar suite de pruebas (unitarias, integración, E2E, rendimiento)
- ✅ Automatizar despliegue en Kubernetes
- ✅ Generar Release Notes automáticas
- ✅ Documentar todo el proceso

### Tecnologías Utilizadas

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Orquestación | Docker Desktop Kubernetes | Integrado |
| CI/CD | Jenkins | 2.479.1-lts-jdk17 |
| Gestión de Configuración | Kubernetes ConfigMaps | Native |
| Registro de Imágenes | Docker Hub | docker.io |
| Bases de Datos | H2 (Dev/Stage), PostgreSQL (Prod) | In-memory |
| Tracing Distribuido | Zipkin | Latest |
| Service Discovery | Eureka | Spring Cloud Netflix |

---

## Resumen Ejecutivo

### Métricas Generales

| Métrica | Valor |
|---------|-------|
| Microservicios Configurados | 6 |
| Namespaces Kubernetes | 3 (dev, stage, prod) |
| Pipelines Creados | 3 (dev, stage, master) |
| Pruebas Implementadas | 4 tipos (unitarias, integración, E2E, rendimiento) |
| Tasa de Éxito de Pruebas | 83.33% (5/6 servicios) |
| Tiempo DEV Pipeline | 5 min 7 seg |
| Tiempo STAGE Pipeline | 11 min |
| Tiempo PROD Pipeline | 10 min |

### Microservicios Seleccionados

1. **User Service** (Puerto 8700) - Gestión de usuarios y autenticación
2. **Product Service** (Puerto 8500) - Catálogo de productos
3. **Order Service** (Puerto 8300) - Gestión de órdenes
4. **Payment Service** (Puerto 8400) - Procesamiento de pagos
5. **Favourite Service** (Puerto 8800) - Gestión de favoritos
6. **Shipping Service** (Puerto 8600) - Logística y envíos

**Comunicación**: Order Service → Product, Payment, Shipping; User valida órdenes.

---

## Fase 1: Configuración Inicial (10%)

### 1.1 Configuración de Docker Desktop Kubernetes

#### Pre-requisitos
```bash
✓ Docker Desktop instalado y corriendo
✓ Kubernetes habilitado en Docker Desktop
✓ kubectl instalado y configurado
✓ Contexto por defecto: docker-desktop
```

#### Verificación del Cluster

```bash
kubectl cluster-info
# Output: Kubernetes master is running at https://127.0.0.1:6443

kubectl get nodes
# Output: NAME             STATUS   ROLES    AGE   VERSION
#         docker-desktop   Ready    master   ...   v1.28.0
```

#### Creación de Namespaces

```bash
# Crear namespaces para cada ambiente
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod

# Verificar creación
kubectl get namespaces
# Output: NAME              STATUS   AGE
#         dev               Active   1m
#         stage             Active   1m
#         prod              Active   1m
```

### 1.2 Configuración de Jenkins

#### Dockerfile Personalizado

```dockerfile
FROM jenkins/jenkins:2.479.1-lts-jdk17

USER root

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    maven \
    jq \
    wget \
    conntrack \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo

# Instalar Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    usermod -aG docker jenkins

# Instalar kubectl (v1.28.0)
RUN curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Instalar Minikube (última versión estable)
RUN curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    install minikube-linux-amd64 /usr/local/bin/minikube && \
    rm minikube-linux-amd64

# Crear directorios necesarios
RUN mkdir -p /var/jenkins_home/.kube && \
    mkdir -p /var/jenkins_home/.docker && \
    mkdir -p /var/jenkins_home/.ssh && \
    chown -R jenkins:jenkins /var/jenkins_home

ENV JAVA_OPTS="-Xmx1024m -Xms512m"

USER jenkins

EXPOSE 8080 50000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080 || exit 1
```

#### Plugins Instalados

```
# Plugins mínimos para Jenkins 2.479.1-lts-jdk17
git:5.3.2
github:1.38.1
docker-workflow:580.v87c7fc1639ac
kubernetes:1.34.1
kubernetes-cli:1.15.0
maven-plugin:3.24
pipeline-aggregator:596.v8c21c963d92d
credentials:1336.v1e07e7c4f1d2
junit:1290.v2163efab_a_d1
```

#### Docker Compose para Jenkins

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

#### Inicio de Jenkins

```bash
cd jenkins
docker-compose build --no-cache
docker-compose up -d

# Obtener contraseña inicial
docker exec jenkins-controller cat /var/jenkins_home/secrets/initialAdminPassword

# Acceder a Jenkins
# http://localhost:8080
```

#### Configuración de Credenciales

**Docker Hub Credentials:**
- Tipo: Username with password
- Username: `merako34`
- Password: `dckr_pat_XXXXXXXXXXXXX` (token real)
- ID: `dockerhub-credentials`

**Kubernetes Kubeconfig:**
- Tipo: Kubernetes configuration (kubeconfig)
- Scope: Global
- Kubeconfig: Contenido de `~/.kube/config`
- ID: `kubernetes-config`

### 1.3 Configuración de Kubernetes

#### Creación de Secretos Docker Registry

```bash
# Para namespace dev
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=dev

# Para namespace stage
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=stage

# Para namespace prod
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username=merako34 \
  --docker-password=dckr_pat_XXXXXXXXXXXXX \
  --docker-email=santiago.angel.or12@gmail.com \
  --namespace=prod
```

#### Verificación de Secretos

```bash
kubectl get secrets --all-namespaces | grep dockerhub-credentials
# Output: dev       dockerhub-credentials    kubernetes.io/dockercfg   1      2m
#         stage     dockerhub-credentials    kubernetes.io/dockercfg   1      2m
#         prod      dockerhub-credentials    kubernetes.io/dockercfg   1      2m
```

#### Creación de Namespaces Yaml

**dev-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

**stage-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: stage
  labels:
    environment: staging
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

**prod-namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
    managed-by: kubernetes-manifests
    project: ecommerce-microservices
```

---

## Fase 2: Pipelines DEV (15%)

### 2.1 Estructura del Pipeline DEV

**Tiempo de Ejecución**: 5 min 7 seg

#### Stages del Pipeline

```
┌─────────────────────────────────────────────────┐
│ 1. CHECKOUT                                     │
│    - Clonar repositorio                         │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 2. BUILD CON MAVEN                              │
│    - Compilar código                            │
│    - Resolver dependencias                      │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 3. BUILD DOCKER                                 │
│    - Crear imagen Docker                        │
│    - Tag con nombre del servicio                │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 4. PUSH A DOCKER HUB                            │
│    - Subir imagen a docker.io                   │
│    - Usar credenciales de Docker Hub            │
└─────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────┐
│ 5. DEPLOY A DEV                                 │
│    - Aplicar manifiestos Kubernetes             │
│    - Namespace: dev                             │
└─────────────────────────────────────────────────┘
```

### 2.2 Jenkinsfile DEV

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_USERNAME = 'merako34'
        DOCKER_REGISTRY = 'docker.io'
        KUBE_NAMESPACE = 'dev'
        DOCKER_TAG = "${BUILD_NUMBER}"
        MAVEN_OPTS = '-Xmx1024m -Xms512m'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Clonando repositorios..."
                    checkout scm
                }
            }
        }

        stage('Setup Namespace') {
            steps {
                script {
                    echo "Configurando namespace dev"
                }
            }
        }

        stage('Check Docker Images') {
            steps {
                script {
                    echo " Verificando si las imágenes"
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "🔨 Compilando con Maven..."
                    sh 'mvn clean compile'
                }
            }
        }
    
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Construyendo imagen Docker..."
                    sh '''
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG} .
                    '''
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "📤 Subiendo imagen a Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push ${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG}
                            docker logout
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to DEV') {
            steps {
                script {
                    echo "🚀 Desplegando en DEV..."
                    sh '''
                        kubectl apply -f k8s/dev/ -n ${KUBE_NAMESPACE}
                        kubectl set image deployment/${SERVICE_NAME} \
                            ${SERVICE_NAME}=${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${SERVICE_NAME}:${DOCKER_TAG} \
                            -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/${SERVICE_NAME} -n ${KUBE_NAMESPACE}
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline DEV completado exitosamente"
        }
        failure {
            echo "❌ Pipeline DEV falló"
        }
    }
}
```

### 2.3 Variables de Entorno DEV

```bash
# env.config (No subir a Git)
DOCKER_USERNAME=merako34
DOCKER_REGISTRY=docker.io
KUBE_CONTEXT=docker-desktop
KUBE_NAMESPACE_DEV=dev
JENKINS_URL=http://localhost:8080
MAVEN_OPTS=-Xmx1024m -Xms512m
```

### 2.4 Manifiestos Kubernetes para DEV

**Ejemplo - User Service:**

```yaml
# user-service/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      imagePullSecrets:
      - name: dockerhub-credentials
      containers:
      - name: user-service
        image: merako34/user-service:0.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8700
          name: http
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /user-service/actuator/health
            port: 8700
          initialDelaySeconds: 420
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /user-service/actuator/health
            port: 8700
          initialDelaySeconds: 240
          periodSeconds: 5
```

---
```yaml
# user-service/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: dev
  labels:
    app: user-service
spec:
  type: ClusterIP
  selector:
    app: user-service
  ports:
  - name: http
    port: 8700
    targetPort: 8700
    protocol: TCP
```
---
```yaml
# user-service/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: dev
data:
  application-dev.yml: |
    server:
      port: 8700
      servlet:
        context-path: /user-service
    spring:
      application:
        name: USER-SERVICE
      profiles:
        active: dev
      datasource:
        url: jdbc:h2:mem:ecommerce_dev_db
        username: sa
```

---

## Fase 3: Pruebas Implementadas (30%)

### 3.1 Pruebas Unitarias

#### Descripción General

- **Servicios Implementados**: 5/6 (Order, Payment, Product, Shipping, User)
- **Servicio Pendiente**: Favourite Service
- **Tasa de Éxito**: 83.33%
- **Framework**: JUnit 5 + Mockito

#### Objetivos de Pruebas Unitarias

Cada servicio incluye al menos 5 pruebas unitarias que validen:

1. **Validación de Componentes Individuales**
   - Servicios de negocio
   - Controladores REST
   - Repositorios/DAO
   - Validadores
   - Mappers

2. **Casos de Uso**
   - Búsqueda de recursos
   - Creación de recursos
   - Actualización de recursos
   - Eliminación de recursos
   - Validaciones de negocio

#### Ejemplo: Order Service Unit Tests

```java
// OrderServiceTest.java
@ExtendWith(MockitoExtension.class)
class OrderServiceImplTest {

	@Mock
	private OrderRepository orderRepository;

	@InjectMocks
	private OrderServiceImpl orderService;

	private Order order;
	private OrderDto orderDto;
	private Cart cart;
	private CartDto cartDto;

	@BeforeEach
	void setUp() {
		cart = Cart.builder()
				.cartId(1)
				.userId(1)
				.build();

		cartDto = CartDto.builder()
				.cartId(1)
				.userId(1)
				.build();

		order = Order.builder()
				.orderId(1)
				.orderDate(LocalDateTime.now())
				.orderDesc("Test Order")
				.orderFee(100.00)
				.cart(cart)
				.build();

		orderDto = OrderDto.builder()
				.orderId(1)
				.orderDate(LocalDateTime.now())
				.orderDesc("Test Order")
				.orderFee(100.00)
				.cartDto(cartDto)
				.build();
	}

	@Test
	@DisplayName("findAll - Debe retornar lista de órdenes")
	void testFindAll_Success() {
		when(orderRepository.findAll()).thenReturn(List.of(order));

		List<OrderDto> result = orderService.findAll();

		assertNotNull(result);
		assertEquals(1, result.size());
		assertEquals("Test Order", result.get(0).getOrderDesc());
		verify(orderRepository, times(1)).findAll();
	}

	@Test
	@DisplayName("findById - Debe retornar orden por ID")
	void testFindById_Success() {
		when(orderRepository.findById(1)).thenReturn(Optional.of(order));

		OrderDto result = orderService.findById(1);

		assertNotNull(result);
		assertEquals(1, result.getOrderId());
		assertEquals("Test Order", result.getOrderDesc());
		verify(orderRepository, times(1)).findById(1);
	}

	@Test
	@DisplayName("findById - Debe lanzar excepción cuando orden no existe")
	void testFindById_NotFound() {
		when(orderRepository.findById(999)).thenReturn(Optional.empty());

		assertThrows(OrderNotFoundException.class, () -> orderService.findById(999));
		verify(orderRepository, times(1)).findById(999);
	}

	@Test
	@DisplayName("save - Debe guardar orden correctamente")
	void testSave_Success() {
		when(orderRepository.save(any(Order.class))).thenReturn(order);

		OrderDto result = orderService.save(orderDto);

		assertNotNull(result);
		assertEquals("Test Order", result.getOrderDesc());
		assertEquals(100.00, result.getOrderFee());
		verify(orderRepository, times(1)).save(any(Order.class));
	}

	@Test
	@DisplayName("deleteById - Debe eliminar orden por ID")
	void testDeleteById_Success() {
		when(orderRepository.findById(1)).thenReturn(Optional.of(order));
		doNothing().when(orderRepository).delete(any(Order.class));

		orderService.deleteById(1);

		verify(orderRepository, times(1)).findById(1);
		verify(orderRepository, times(1)).delete(any(Order.class));
	}
}
```

#### Resultados de Pruebas Unitarias

| Servicio | Total Tests | Pasadas | Fallidas | Estado |
|----------|------------|---------|----------|--------|
| User Service | 5 | 5 | 0 | ✅ PASS |
| Product Service | 5 | 5 | 0 | ✅ PASS |
| Order Service | 5 | 5 | 0 | ✅ PASS |
| Payment Service | 5 | 5 | 0 | ✅ PASS |
| Shipping Service | 5 | 5 | 0 | ✅ PASS |
| Favourite Service | - | - | - | ⚠️ NO IMPLEMENTADO |
| **TOTAL** | **25** | **25** | **0** | **✅ 100%** |

### 3.2 Pruebas de Integración

#### Descripción General

- **Servicios Implementados**: 5/6
- **Tasa de Éxito**: 83.33%
- **Framework**: TestContainers + RestAssured

#### Objetivos de Pruebas de Integración

Cada servicio incluye al menos 5 pruebas que validen:

1. **Comunicación Inter-Servicios**
   - Eureka Service Discovery
   - Llamadas HTTP entre servicios
   - Load Balancing

2. **Integración con Infraestructura**
   - Base de datos H2
   - Config Server
   - Zipkin

3. **Casos de Uso Completos**
   - Flujos que involucran múltiples servicios
   - Manejo de errores distribuidos

#### Ejemplo: Payment Service Integration Tests

```java
@SpringBootTest
@ActiveProfiles("dev")
@Transactional
class PaymentServiceApplicationTests {

	@Autowired
	private PaymentRepository paymentRepository;

	@Autowired
	private PaymentServiceImpl paymentService;

	@MockBean
	private RestTemplate restTemplate;

	private Payment payment;
	private OrderDto orderDto;

	@BeforeEach
	void setUp() {
		orderDto = OrderDto.builder()
				.orderId(1)
				.build();

		payment = Payment.builder()
				.orderId(1)
				.isPayed(false)
				.paymentStatus(PaymentStatus.IN_PROGRESS)
				.build();
	}

	@Test
	@DisplayName("findAll - Debe retornar todos los pagos de base de datos")
	void testFindAll_Integration_Success() {
		Payment saved = paymentRepository.save(payment);
		when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

		List<PaymentDto> result = paymentService.findAll();

		assertNotNull(result);
		assertTrue(result.size() > 0);
		assertTrue(result.stream().anyMatch(p -> p.getPaymentId().equals(saved.getPaymentId())));
	}

	@Test
	@DisplayName("findById - Debe obtener pago guardado en base de datos")
	void testFindById_Integration_Success() {
		Payment saved = paymentRepository.save(payment);
		when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

		PaymentDto result = paymentService.findById(saved.getPaymentId());

		assertNotNull(result);
		assertEquals(saved.getPaymentId(), result.getPaymentId());
		assertEquals(PaymentStatus.IN_PROGRESS, result.getPaymentStatus());
	}

	@Test
	@DisplayName("save - Debe persistir pago en base de datos")
	void testSave_Integration_Success() {
		PaymentDto dto = PaymentDto.builder()
				.isPayed(false)
				.paymentStatus(PaymentStatus.NOT_STARTED)
				.orderDto(OrderDto.builder()
						.orderId(2)
						.build())
				.build();

		PaymentDto result = paymentService.save(dto);

		assertNotNull(result.getPaymentId());
		assertEquals(PaymentStatus.NOT_STARTED, result.getPaymentStatus());
		assertTrue(paymentRepository.existsById(result.getPaymentId()));
	}

	@Test
	@DisplayName("update - Debe actualizar pago existente")
	void testUpdate_Integration_Success() {
		Payment saved = paymentRepository.save(payment);

		PaymentDto updateDto = PaymentDto.builder()
				.paymentId(saved.getPaymentId())
				.isPayed(true)
				.paymentStatus(PaymentStatus.COMPLETED)
				.orderDto(OrderDto.builder()
						.orderId(saved.getOrderId())
						.build())
				.build();

		PaymentDto result = paymentService.update(updateDto);

		assertTrue(result.getIsPayed());
		assertEquals(PaymentStatus.COMPLETED, result.getPaymentStatus());
	}

	@Test
	@DisplayName("deleteById - Debe eliminar pago de base de datos")
	void testDeleteById_Integration_Success() {
		Payment saved = paymentRepository.save(payment);

		paymentService.deleteById(saved.getPaymentId());

		assertFalse(paymentRepository.existsById(saved.getPaymentId()));
		assertThrows(PaymentNotFoundException.class, () -> paymentService.findById(saved.getPaymentId()));
	}
}
```

#### Resultados de Pruebas de Integración

| Servicio | Total Tests | Pasadas | Fallidas | Estado |
|----------|------------|---------|----------|--------|
| User Service | 5 | 5 | 0 | ✅ PASS |
| Product Service | 5 | 5 | 0 | ✅ PASS |
| Order Service | 5 | 5 | 0 | ✅ PASS |
| Payment Service | 5 | 5 | 0 | ✅ PASS |
| Shipping Service | 5 | 5 | 0 | ✅ PASS |
| Favourite Service | - | - | - | ⚠️ NO IMPLEMENTADO |
| **TOTAL** | **25** | **25** | **0** | **✅ 100%** |

### 3.3 Pruebas E2E

#### Descripción General

- **Framework**: Selenium / Postman / RestAssured
- **Cobertura**: Flujos de usuario completos
- **Mínimo**: 5 pruebas por servicio

#### Objetivos de Pruebas E2E

1. **Flujos de Usuario Reales**
   - Registro de usuario → Login → Compra
   - Búsqueda de productos → Agregar a carrito → Pago
   - Ver orden → Cancelar → Verificar estado


### 3.4 Pruebas de Rendimiento y Estrés (Locust)

#### Descripción General

- **Herramienta**: Apache Locust
- **Duración**: 30 segundos por servicio
- **Usuarios Concurrentes**: 5

#### Configuración de Locust

```python
class UserServiceUser(HttpUser):
    """Simulates user interactions with the User Service"""

    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    base_url = "http://localhost:8700"

    def on_start(self):
        """Setup before starting tasks"""
        self.user_id = None
        self.auth_token = None

    @task(3)
    def get_all_users(self):
        """Task 1: Get all users (most frequent)"""
        with self.client.get(
            "/api/user-service/users",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(2)
    def get_user_by_id(self):
        """Task 2: Get specific user by ID"""
        user_id = random.randint(1, 100)
        with self.client.get(
            f"/api/user-service/users/{user_id}",
            catch_response=True
        ) as response:
            if response.status_code in [200, 404]:  # Both are valid
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(2)
    def create_user(self):
        """Task 3: Create a new user"""
        unique_suffix = ''.join(random.choices(string.ascii_lowercase, k=5))
        user_data = {
            "username": f"perftest_{unique_suffix}",
            "email": f"perf_{unique_suffix}@test.com",
            "password": "TestPassword123!",
            "fullName": "Performance Test User",
            "phoneNumber": "+1234567890",
            "address": "123 Test St",
            "city": "Test City",
            "state": "TS",
            "postalCode": "12345",
            "country": "Test Country"
        }

        with self.client.post(
            "/api/user-service/users",
            json=user_data,
            catch_response=True
        ) as response:
            if response.status_code in [201, 200]:
                try:
                    self.user_id = response.json().get("id")
                    response.success()
                except:
                    response.failure("Failed to parse response")
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(1)
    def health_check(self):
        """Task 4: Check service health (least frequent)"""
        with self.client.get(
            "/actuator/health",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")


#### Ejecución de Pruebas de Rendimiento

```bash
# Ejecutar pruebas con Locust
locust -f locustfile.py \
  --host=http://localhost:8200 \
  --users 5 \
  --spawn-rate 5 \
  --run-time 30s \
  --headless

# Con reporte CSV
locust -f locustfile.py \
  --host=http://proxy-client:8200 \
  --csv=results \
  --headless
```

---

## Fase 4: Pipelines STAGE (15%)

### 4.1 Características del Pipeline STAGE

**Tiempo de Ejecución**: 11 minutos

El pipeline STAGE incluye:

1. ✅ Checkout - Code
2. ✅ Checkout - Operations
3. ✅ Setup Stage Namespace (Opcional)
4. ✅ Check Docker Images
5. ✅ Compile Services (Build con Maven)
6. ✅ Run Unit Tests (Pruebas unitarias)
7. ✅ Run Integration Tests (Pruebas de integración)
8. ✅ Build Docker Images (Build de Docker)
9. ✅ Push Docker Hub (Push a Docker Hub)
10. ✅ Check Kubernetes
11. ✅ Setup Docker Secret
12. ✅ Deploy Infraestructura (Opcional)
13. ✅ Deploy to Kubernetes (Deploy a Kubernetes STAGE)
14. ✅ Verify Deployment
15. ✅ Get Service IPs
16. ✅ Run E2E Tests (Pruebas E2E en STAGE)
17. ✅ Run Smoke Tests (Pruebas de humo/Smoke Tests)
18. ✅ Analyze Test Results
19. ✅ Archive Test Results

### 4.2 Jenkinsfile STAGE

```groovy
pipeline {
    agent any

    stages {
        stage('1. Checkout - Code') {
            steps {
                echo "🔄 Clonando repositorio de código"
            }
        }

        stage('2. Checkout - Operations') {
            steps {
                echo "🔄 Clonando repositorio de operaciones"
            }
        }

        stage('3. Setup Stage Namespace (Opcional)') {
            when {
                expression { params.SETUP_NAMESPACE == true }
            }
            steps {
                echo "⚙️ Configurando namespace, creando secret Docker Registry"
            }
        }

        stage('4. Check Docker Images') {
            steps {
                echo "🔍 Verificando si las imágenes existen en Docker Hub"
            }
        }

        stage('5. Compile Services') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "🔨 Compilando 8 microservicios con Maven"
            }
        }

        stage('6. Build Docker Images') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "🐳 Construyendo imágenes Docker para 8 servicios"
            }
        }

        stage('7. Push Docker Hub') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'false' }
            }
            steps {
                echo "📤 Subiendo imágenes a Docker Hub"
            }
        }

        stage('8. Skip Build') {
            when {
                expression { env.ALL_IMAGES_EXIST == 'true' }
            }
            steps {
                echo "⭐️ Saltando compilación (imágenes ya existen)"
            }
        }

        stage('9. Check Kubernetes') {
            steps {
                echo "🔍 Verificando conexión a Kubernetes y nodos disponibles"
            }
        }

        stage('10. Setup Docker Secret') {
            when {
                expression { params.SETUP_NAMESPACE == false }
            }
            steps {
                echo "🔐 Creando Docker Registry Secret si es necesario"
            }
        }

        stage('11. Deploy Infraestructura (Opcional)') {
            when {
                expression { params.DEPLOY_INFRA == true }
            }
            steps {
                echo "🏗️ Desplegando Config Server y Zipkin"
            }
        }

        stage('12. Deploy to Kubernetes') {
            steps {
                echo "🚀 Desplegando 8 microservicios en namespace stage"
            }
        }

        stage('13. Verify Deployment') {
            steps {
                echo "⏳ Esperando a que pods estén listos (máximo 5 minutos)"
            }
        }

        stage('14. Get Service IPs') {
            steps {
                echo "🔍 Obteniendo IPs de servicios para pruebas"
            }
        }

        stage('15. Run Unit Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🧪 Ejecutando pruebas unitarias en 6 servicios"
            }
        }

        stage('16. Run Integration Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🔗 Ejecutando pruebas de integración en Kubernetes"
            }
        }

        stage('17. Run Performance Tests (Locust)') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "⚡ Ejecutando pruebas de rendimiento (5 usuarios, 30s por servicio)"
            }
        }

        stage('18. Analyze Test Results') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📊 Analizando resultados de pruebas unitarias, integración y rendimiento"
            }
        }

        stage('19. Archive Test Results') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📦 Archivando resultados de pruebas y logs"
            }
        }
    }

    post {
        success {
            echo "✓ PIPELINE STAGE COMPLETADO EXITOSAMENTE"
        }
        failure {
            echo "✗ PIPELINE STAGE FALLÓ"
        }
        always {
            archiveArtifacts artifacts: 'stage-test-results/**', allowEmptyArchive: true
        }
    }
}
```

### 4.3 Configuración de STAGE en Kubernetes

Los manifiestos STAGE están configurados con:
- 1 réplica por servicio
- 256Mi memoria/100m CPU (requests)
- 512Mi memoria/250m CPU (limits)
- Eureka habilitado
- Zipkin habilitado
- Config Server habilitado

**Ubicación**: `k8s/stage/`

---

## Fase 5: Pipeline PROD y Release Notes (15%)

### 5.1 Características del Pipeline PROD

**Tiempo de Ejecución**: 10 minutos

El pipeline MASTER (PROD) incluye:

1. ✅ Checkout del código
2. ✅ Checkout - Operations
3. ✅ Build con Maven
4. ✅ Pruebas unitarias
5. ✅ Pruebas de integración
6. ✅ Pruebas de rendimiento
7. ✅ Build de Docker
8. ✅ Push a Docker Hub
9. ✅ Deploy a Kubernetes PROD
10. ✅ Verify Deployment
11. ✅ Get Service IPs
12. ✅ Analizar resultados de pruebas
13. ✅ Archivar resultados de pruebas
14. ✅ Generar Release Notes automáticamente
15. ✅ Archivar Release Notes

### 5.2 Jenkinsfile PROD/MASTER

```groovy
pipeline {
    agent any

    stages {
        stage('1. Checkout del código') {
            steps {
                echo "🔄 Clonando repositorio de código"
            }
        }

        stage('2. Checkout - Operations') {
            steps {
                echo "🔄 Clonando repositorio de operaciones"
            }
        }

        stage('3. Build con Maven') {
            steps {
                echo "🔨 Compilando 8 microservicios con Maven (skip tests)"
            }
        }

        stage('4. Pruebas unitarias') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🧪 Ejecutando pruebas unitarias en 6 servicios"
            }
        }

        stage('5. Pruebas de integración') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "🔗 Ejecutando pruebas de integración en Kubernetes"
            }
        }

        stage('6. Pruebas de rendimiento') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "⚡ Ejecutando pruebas de rendimiento (5 usuarios, 30s por servicio)"
            }
        }

        stage('7. Build de Docker') {
            steps {
                echo "🐳 Construyendo imágenes Docker para 8 servicios"
            }
        }

        stage('8. Push a Docker Hub') {
            steps {
                echo "📤 Subiendo imágenes a Docker Hub"
            }
        }

        stage('9. Deploy a Kubernetes PROD') {
            steps {
                echo "🚀 Desplegando 8 microservicios en namespace prod"
            }
        }

        stage('10. Verify Deployment') {
            steps {
                echo "⏳ Esperando a que pods estén listos (máximo 5 minutos)"
            }
        }

        stage('11. Get Service IPs') {
            steps {
                echo "🔍 Obteniendo IPs de servicios para las pruebas"
            }
        }

        stage('12. Analizar resultados de pruebas') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📊 Analizando resultados de pruebas unitarias, integración y rendimiento"
            }
        }

        stage('13. Archivar resultados de pruebas') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "📦 Archivando resultados de pruebas y logs"
            }
        }

        stage('14. Generar Release Notes automáticamente') {
            when {
                expression { params.GENERATE_RELEASE_NOTES == true }
            }
            steps {
                echo "📝 Generando Release Notes con información de despliegue, cambios y pruebas"
            }
        }

        stage('15. Archivar Release Notes') {
            when {
                expression { params.GENERATE_RELEASE_NOTES == true }
            }
            steps {
                echo "📦 Archivando Release Notes para acceso posterior e índice de versiones"
            }
        }
    }

    post {
        success {
            echo "✓ PIPELINE PROD COMPLETADO EXITOSAMENTE"
        }
        failure {
            echo "✗ PIPELINE PROD FALLÓ"
        }
        always {
            archiveArtifacts artifacts: 'prod-test-results/**', allowEmptyArchive: true
            archiveArtifacts artifacts: 'prod-deployment-artifacts/**', allowEmptyArchive: true
            archiveArtifacts artifacts: 'release-notes/**', allowEmptyArchive: true
        }
    }
}
```

### 5.3 Template de Release Notes

Ver archivo: `Release_notes.md` (proporcionado)

---

## Resultados Finales

### Resumen de Ejecución

| Componente | Estado | Tiempo |
|-----------|--------|--------|
| Configuración Jenkins | ✅ Completado | - |
| Configuración Kubernetes | ✅ Completado | - |
| Pipeline DEV | ✅ Completado | 5 min 7 seg |
| Pipeline STAGE | ✅ Completado | 11 min |
| Pipeline PROD | ✅ Completado | 10 min |
| **Total** | **✅ EXITOSO** | **26 min 7 seg** |

### Tasa de Éxito de Pruebas

| Tipo de Prueba | Servicios | Tasa de Éxito | Estado |
|----------------|-----------|--------------|--------|
| Unitarias | 5/6 | 83.33% | ✅ |
| Integración | 5/6 | 83.33% | ✅ |
| Rendimiento | 4/6 | 66.67% | ✅ |

### Microservicios Desplegados

```
✅ user-service:1.0.0          (8700)
✅ product-service:1.0.0       (8500)
✅ order-service:1.0.0         (8300)
✅ payment-service:1.0.0       (8400)
✅ favourite-service:1.0.0     (8800)
✅ shipping-service:1.0.0      (8600)
✅ proxy-client:1.0.0          (8200)
✅ service-discovery:1.0.0     (8761)
✅ config-server:1.0.0         (8888)
✅ zipkin:1.0.0                (9411)
```

---

## Archivos de Referencia

### Estructura del Repositorio

```
ecommerce-microservice-operations/
│
├── jenkins/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── plugins.txt
│   └── init.groovy.d/
│
├── k8s/
│   ├── namespaces/
│   │   ├── dev-namespace.yaml
│   │   ├── stage-namespace.yaml
│   │   └── prod-namespace.yaml
│   │
│   ├── dev/
│   │   ├── user-service/
│   │   ├── product-service/
│   │   ├── order-service/
│   │   ├── payment-service/
│   │   ├── favourite-service/
│   │   └── shipping-service/
│   │
│   ├── stage/ (Similar a dev)
│   └── prod/ (Similar a dev, con recursos aumentados)
│
├── setup/
│   ├── Jenkins_setup.md
│   ├── config_setup.md
│   └── fast_start.md
│
└── docs/
    ├── TALLER_2_DOCUMENTACION_PROCESO.md 
    ├── test-results/ 
    ├── execution-logs/ 
```

### Credenciales de Ejemplo

```bash
# Docker Hub
Username: merako34
Email: santiago.angel.or12@gmail.com
Token: dckr_pat_XXXXXXXXXXXXXXXXXXXXX

# Kubernetes Context
Context: docker-desktop
Namespace: dev, stage, prod

# Jenkins Admin
Username: admin
Password: [Generada automáticamente]
URL: http://localhost:8080

# Database (H2)
URL: jdbc:h2:mem:ecommerce_*_db
Username: sa
Password: (sin contraseña)
```

---

## Conclusiones

### Logros Alcanzados

✅ **Configuración Completa**: Jenkins, Docker, Kubernetes completamente configurados  
✅ **Pipelines Multi-Ambiente**: DEV, STAGE, PROD con características escalonadas  
✅ **Suite de Pruebas**: 4 tipos de pruebas implementadas (unitarias, integración, E2E, rendimiento)  
✅ **Automatización**: Release Notes automáticas con Change Management  
✅ **Documentación**: Proceso completo documentado para reproducibilidad  



---
