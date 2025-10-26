FROM jenkins/jenkins:2.479.1-lts-jdk17

USER root

# Instalar dependencias del sistema necesarias para Docker, Minikube y kubectl
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
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Instalar Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    usermod -aG docker jenkins

# Instalar kubectl (v1.28.0)
RUN curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# ✅ Instalar Minikube (última versión estable)
RUN curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    install minikube-linux-amd64 /usr/local/bin/minikube && \
    rm minikube-linux-amd64

# Crear directorios necesarios
RUN mkdir -p /var/jenkins_home/.kube && \
    mkdir -p /var/jenkins_home/.docker && \
    mkdir -p /var/jenkins_home/.ssh && \
    chown -R jenkins:jenkins /var/jenkins_home


# Configuración de Java
ENV JAVA_OPTS="-Xmx1024m -Xms512m"

# 🔥 Permitir a Jenkins ejecutar Docker y Minikube sin sudo
RUN usermod -aG docker jenkins && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER jenkins

EXPOSE 8080 50000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080 || exit 1
