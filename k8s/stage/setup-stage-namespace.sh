#!/bin/bash

# Script para configurar el namespace stage con todos los servicios e infraestructura necesaria
# Uso: ./setup-stage-namespace.sh <docker-username> <docker-token> <docker-email>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar argumentos
if [ $# -ne 3 ]; then
    log_error "Uso: $0 <docker-username> <docker-token> <docker-email>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 tu_usuario tu_token tu_email@example.com"
    exit 1
fi

DOCKER_USERNAME=$1
DOCKER_TOKEN=$2
DOCKER_EMAIL=$3

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl no está instalado. Por favor instala kubectl."
    exit 1
fi

log_info "Iniciando configuración del namespace stage..."
echo ""

# Crear el namespace si no existe
log_info "Verificando namespace 'stage'..."
if kubectl get namespace stage &> /dev/null; then
    log_info "Namespace 'stage' ya existe"
else
    log_info "Creando namespace 'stage'..."
    kubectl create namespace stage
    log_info "Namespace 'stage' creado exitosamente"
fi

echo ""

# Crear el secret de Docker Registry
log_info "Creando secret de Docker Registry..."
kubectl create secret docker-registry dockerhub-credentials \
  --docker-server=docker.io \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_TOKEN" \
  --docker-email="$DOCKER_EMAIL" \
  --namespace=stage \
  --dry-run=client -o yaml | kubectl apply -f -

log_info "Secret 'dockerhub-credentials' creado/actualizado"

echo ""

# Aplicar ConfigMap del Config Server
log_info "Aplicando ConfigMap del Config Server..."
kubectl apply -f "$(dirname "$0")/config-server/configmap.yaml"

echo ""

# Aplicar Config Server
log_info "Desplegando Config Server..."
kubectl apply -f "$(dirname "$0")/config-server/service.yaml"
kubectl apply -f "$(dirname "$0")/config-server/deployment.yaml"

log_info "Config Server desplegado"

echo ""

# Aplicar Zipkin
log_info "Desplegando Zipkin..."
kubectl apply -f "$(dirname "$0")/zipkin/service.yaml"
kubectl apply -f "$(dirname "$0")/zipkin/deployment.yaml"

log_info "Zipkin desplegado"

echo ""

# Esperar a que los servicios estén listos
log_info "Esperando a que Config Server esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/config-server -n stage 2>/dev/null || log_warn "Config Server tardó en iniciar"

log_info "Esperando a que Zipkin esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/zipkin -n stage 2>/dev/null || log_warn "Zipkin tardó en iniciar"

echo ""

# Mostrar status
log_info "Estado de los servicios en el namespace stage:"
echo ""
kubectl get services -n stage
echo ""
kubectl get deployments -n stage
echo ""
kubectl get pods -n stage

echo ""
log_info "Configuración del namespace stage completada"
echo ""
echo "Próximos pasos:"
echo "  1. Verifica que los pods estén en estado Running:"
echo "     kubectl get pods -n stage"
echo ""
echo "  2. Despliega los microservicios:"
echo "     kubectl apply -f k8s/stage/"
echo ""
echo "  3. Verifica el estado:"
echo "     kubectl get all -n stage"
echo ""
