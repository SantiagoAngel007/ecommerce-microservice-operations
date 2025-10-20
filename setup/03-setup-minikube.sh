#!/bin/bash

###############################################################################
# Script: 03-setup-minikube.sh
# Descripción: Configura y levanta Minikube para el proyecto
# Autor: Taller 2 - Pruebas y Lanzamiento
###############################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_step() { echo -e "${BLUE}▶ $1${NC}"; }

echo "=========================================="
echo "Configurando Minikube"
echo "=========================================="

# 1. Verificar instalación de Minikube
print_step "Verificando instalación de Minikube..."
if ! command -v minikube &> /dev/null; then
    print_error "Minikube no está instalado. Ejecuta primero: ./01-install-prerequisites.sh"
    exit 1
fi
print_success "Minikube está instalado ($(minikube version --short))"

# 2. Detener cluster existente si existe
print_step "Deteniendo cluster existente (si existe)..."
minikube delete 2>/dev/null || true
print_success "Cluster anterior eliminado"

# 3. Configurar recursos para Minikube
print_step "Configurando cluster Minikube..."
print_info "Configuración: 4 CPUs, 8GB RAM, 40GB disco"

# Iniciar Minikube con configuración optimizada
minikube start \
    --driver=docker \
    --cpus=4 \
    --memory=8192 \
    --disk-size=40g \
    --kubernetes-version=v1.28.0 \
    --addons=ingress,dashboard,metrics-server,registry

if [ $? -ne 0 ]; then
    print_error "Error al iniciar Minikube"
    exit 1
fi
print_success "Minikube iniciado correctamente"

# 4. Habilitar addons necesarios
print_step "Habilitando addons de Minikube..."
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server
minikube addons enable registry
print_success "Addons habilitados"

# 5. Configurar contexto de kubectl
print_step "Configurando kubectl..."
kubectl config use-context minikube
print_success "Contexto de kubectl configurado"

# 6. Esperar a que el cluster esté listo
print_step "Esperando a que el cluster esté listo..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s
print_success "Cluster listo"

# 7. Crear namespaces para los diferentes ambientes
print_step "Creando namespaces..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace stage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespaces creados: dev, stage, prod"

# 8. Configurar Docker para usar registro de Minikube
print_step "Configurando Docker con Minikube..."
eval $(minikube docker-env)
print_success "Docker configurado para usar registro de Minikube"

# 9. Crear secreto para Docker Hub (placeholder)
print_step "Creando secreto placeholder para Docker Hub..."
for ns in dev stage prod; do
    kubectl create secret generic dockerhub-credentials \
        --from-literal=username=placeholder \
        --from-literal=password=placeholder \
        --namespace=$ns \
        --dry-run=client -o yaml | kubectl apply -f -
done
print_success "Secretos placeholder creados"

# 10. Verificar estado del cluster
print_step "Verificando estado del cluster..."
echo ""
kubectl get nodes
echo ""
kubectl get namespaces
echo ""

# 11. Información de acceso al dashboard
DASHBOARD_URL=$(minikube dashboard --url 2>/dev/null &)
sleep 5

echo "=========================================="
print_success "¡Minikube configurado exitosamente!"
echo "=========================================="
echo ""
echo "📋 Información del cluster:"
echo "   Status:       $(minikube status | grep host | awk '{print $2}')"
echo "   IP:           $(minikube ip)"
echo "   Driver:       docker"
echo "   Kubernetes:   $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"
echo ""
echo "🌐 Namespaces creados:"
echo "   • dev      (desarrollo)"
echo "   • stage    (staging/pruebas)"
echo "   • prod     (producción)"
echo ""
echo "🔧 Comandos útiles:"
echo "   Dashboard:    minikube dashboard"
echo "   Status:       minikube status"
echo "   Stop:         minikube stop"
echo "   Start:        minikube start"
echo "   Delete:       minikube delete"
echo "   SSH:          minikube ssh"
echo "   Logs:         minikube logs"
echo ""
echo "🐳 Docker:"
echo "   Para usar Docker de Minikube:"
echo "   eval \$(minikube docker-env)"
echo ""
echo "📝 Siguiente paso:"
echo "   Ejecuta: ./04-configure-credentials.sh"
echo "=========================================="

# Guardar IP de Minikube en archivo
minikube ip > /tmp/minikube-ip.txt
print_info "IP de Minikube guardada en /tmp/minikube-ip.txt"