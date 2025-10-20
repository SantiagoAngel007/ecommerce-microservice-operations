#!/bin/bash

###############################################################################
# Script: 02-setup-jenkins.sh
# Descripción: Configura y levanta Jenkins en Docker
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
echo "Configurando Jenkins"
echo "=========================================="

# Verificar que estamos en el directorio correcto
if [ ! -d "../jenkins" ]; then
    print_error "No se encuentra el directorio jenkins/. Asegúrate de ejecutar este script desde setup/"
    exit 1
fi

cd ../jenkins

# 1. Verificar que Docker está corriendo
print_step "Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker no está corriendo. Por favor inicia Docker Desktop."
    exit 1
fi
print_success "Docker está corriendo"

# 2. Detener contenedores existentes
print_step "Deteniendo contenedores Jenkins existentes..."
docker-compose down -v 2>/dev/null || true
docker rm -f jenkins-controller jenkins-agent 2>/dev/null || true
print_success "Contenedores anteriores detenidos"

# 3. Crear directorios necesarios
print_step "Creando estructura de directorios..."
mkdir -p init.groovy.d
mkdir -p jobs
print_success "Directorios creados"

# 4. Crear archivo de configuración inicial de Jenkins
print_step "Creando configuración inicial de Jenkins..."
cat > init.groovy.d/basic-security.groovy << 'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Configurar usuario admin
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Configurar autorización
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Deshabilitar CSRF si es necesario (no recomendado en producción)
instance.setCrumbIssuer(null)

instance.save()

println("Configuración de seguridad básica aplicada")
EOF
print_success "Configuración de seguridad creada"

# 5. Crear configuración de Docker en Jenkins
cat > init.groovy.d/configure-docker.groovy << 'EOF'
#!groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.docker.commons.credentials.*

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = SystemCredentialsProvider.getInstance().getStore()

// Nota: Las credenciales de Docker Hub se configurarán manualmente
println("Jenkins configurado para usar Docker")
EOF
print_success "Configuración de Docker creada"

# 6. Construir imagen de Jenkins personalizada
print_step "Construyendo imagen Docker de Jenkins (esto puede tardar varios minutos)..."
docker-compose build --no-cache
print_success "Imagen de Jenkins construida"

# 7. Iniciar Jenkins
print_step "Iniciando Jenkins..."
docker-compose up -d
print_success "Jenkins iniciado"

# 8. Esperar a que Jenkins esté listo
print_step "Esperando a que Jenkins esté disponible..."
echo -n "Iniciando"
MAX_WAIT=180
COUNTER=0
until curl -s http://localhost:8081/login > /dev/null 2>&1; do
    if [ $COUNTER -ge $MAX_WAIT ]; then
        print_error "Jenkins no inició en el tiempo esperado"
        echo "Logs de Jenkins:"
        docker-compose logs jenkins
        exit 1
    fi
    echo -n "."
    sleep 5
    COUNTER=$((COUNTER+5))
done
echo ""
print_success "Jenkins está disponible"

# 9. Mostrar información
echo ""
echo "=========================================="
print_success "¡Jenkins configurado exitosamente!"
echo "=========================================="
echo ""
echo "📋 Información de acceso:"
echo "   URL:      http://localhost:8081"
echo "   Usuario:  admin"
echo "   Password: admin123"
echo ""
echo "🔧 Comandos útiles:"
echo "   Ver logs:     docker-compose logs -f jenkins"
echo "   Detener:      docker-compose stop"
echo "   Reiniciar:    docker-compose restart"
echo "   Eliminar:     docker-compose down -v"
echo ""
echo "📝 Siguiente paso:"
echo "   1. Accede a http://localhost:8081"
echo "   2. Inicia sesión con las credenciales de arriba"
echo "   3. Ejecuta: ../setup/04-configure-credentials.sh"
echo ""
print_info "IMPORTANTE: Cambia la contraseña por defecto en producción"
echo "=========================================="

# Abrir navegador automáticamente (opcional)
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8081 2>/dev/null || true
elif command -v open > /dev/null; then
    open http://localhost:8081 2>/dev/null || true
fi