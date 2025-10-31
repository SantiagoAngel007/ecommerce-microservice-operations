# Script para configurar el namespace stage con todos los servicios e infraestructura necesaria
# Uso: .\setup-stage-namespace.ps1 -DockerUsername "tu_usuario" -DockerToken "tu_token" -DockerEmail "tu_email@example.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerUsername,

    [Parameter(Mandatory=$true)]
    [string]$DockerToken,

    [Parameter(Mandatory=$true)]
    [string]$DockerEmail
)

# Funciones para imprimir mensajes
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar que kubectl está disponible
try {
    $null = kubectl version --client 2>$null
} catch {
    Write-Error-Custom "kubectl no está instalado o no está en el PATH"
    exit 1
}

Write-Info "Iniciando configuración del namespace stage..."
Write-Host ""

# Crear el namespace si no existe
Write-Info "Verificando namespace 'stage'..."
try {
    kubectl get namespace stage | Out-Null
    Write-Info "Namespace 'stage' ya existe"
} catch {
    Write-Info "Creando namespace 'stage'..."
    kubectl create namespace stage
    Write-Info "Namespace 'stage' creado exitosamente"
}

Write-Host ""

# Crear el secret de Docker Registry
Write-Info "Creando secret de Docker Registry..."
try {
    kubectl create secret docker-registry dockerhub-credentials `
        --docker-server=docker.io `
        --docker-username=$DockerUsername `
        --docker-password=$DockerToken `
        --docker-email=$DockerEmail `
        --namespace=stage `
        --dry-run=client -o yaml | kubectl apply -f -

    Write-Info "Secret 'dockerhub-credentials' creado/actualizado"
} catch {
    Write-Error-Custom "Error al crear el secret: $_"
    exit 1
}

Write-Host ""

# Obtener el directorio del script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Aplicar ConfigMap del Config Server
Write-Info "Aplicando ConfigMap del Config Server..."
try {
    kubectl apply -f "$ScriptDir\config-server\configmap.yaml"
} catch {
    Write-Error-Custom "Error al aplicar ConfigMap: $_"
    exit 1
}

Write-Host ""

# Aplicar Config Server
Write-Info "Desplegando Config Server..."
try {
    kubectl apply -f "$ScriptDir\config-server\service.yaml"
    kubectl apply -f "$ScriptDir\config-server\deployment.yaml"
    Write-Info "Config Server desplegado"
} catch {
    Write-Error-Custom "Error al desplegar Config Server: $_"
    exit 1
}

Write-Host ""

# Aplicar Zipkin
Write-Info "Desplegando Zipkin..."
try {
    kubectl apply -f "$ScriptDir\zipkin\service.yaml"
    kubectl apply -f "$ScriptDir\zipkin\deployment.yaml"
    Write-Info "Zipkin desplegado"
} catch {
    Write-Error-Custom "Error al desplegar Zipkin: $_"
    exit 1
}

Write-Host ""

# Esperar a que los servicios estén listos
Write-Info "Esperando a que Config Server esté listo..."
try {
    kubectl wait --for=condition=available --timeout=300s deployment/config-server -n stage 2>$null
} catch {
    Write-Warn "Config Server tardó en iniciar o error en espera"
}

Write-Info "Esperando a que Zipkin esté listo..."
try {
    kubectl wait --for=condition=available --timeout=300s deployment/zipkin -n stage 2>$null
} catch {
    Write-Warn "Zipkin tardó en iniciar o error en espera"
}

Write-Host ""

# Mostrar status
Write-Info "Estado de los servicios en el namespace stage:"
Write-Host ""
kubectl get services -n stage
Write-Host ""
kubectl get deployments -n stage
Write-Host ""
kubectl get pods -n stage

Write-Host ""
Write-Info "Configuración del namespace stage completada"
Write-Host ""
Write-Host "Próximos pasos:"
Write-Host "  1. Verifica que los pods estén en estado Running:"
Write-Host "     kubectl get pods -n stage"
Write-Host ""
Write-Host "  2. Despliega los microservicios:"
Write-Host "     kubectl apply -f k8s/stage/"
Write-Host ""
Write-Host "  3. Verifica el estado:"
Write-Host "     kubectl get all -n stage"
Write-Host ""
