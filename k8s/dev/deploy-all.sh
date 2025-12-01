#!/usr/bin/env fish
# Script para desplegar todos los microservicios en DEV
# Orden: infraestructura primero, luego servicios de negocio

set -x

echo "🚀 Desplegando microservicios en namespace dev..."
echo ""

# 1. Crear namespace si no existe
echo "📦 Creando namespace dev..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
echo ""

# 2. Desplegar servicios de infraestructura primero
echo "🔧 Desplegando servicios de infraestructura..."
echo "  → Config Server"
kubectl apply -f config-server/
sleep 5

echo "  → Service Discovery (Eureka)"
kubectl apply -f service-discovery/
sleep 5

echo "  → Zipkin (Tracing)"
kubectl apply -f zipkin/
sleep 5

echo "  → API Gateway (Proxy Client)"
kubectl apply -f proxy-client/
sleep 5

echo ""
echo "⏳ Esperando que infraestructura esté lista..."
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=120s
echo ""

# 3. Desplegar microservicios de negocio
echo "💼 Desplegando microservicios de negocio..."
echo "  → User Service"
kubectl apply -f user-service/

echo "  → Product Service"
kubectl apply -f product-service/

echo "  → Order Service"
kubectl apply -f order-service/

echo "  → Payment Service"
kubectl apply -f payment-service/

echo "  → Shipping Service"
kubectl apply -f shipping-service/

echo "  → Favourite Service"
kubectl apply -f favourite-service/

echo ""
echo "⏳ Esperando que los pods estén listos..."
sleep 30

echo ""
echo "📊 Estado actual del deployment:"
kubectl get all -n dev

echo ""
echo "🌐 Servicios expuestos (LoadBalancer):"
kubectl get svc -n dev | grep LoadBalancer

echo ""
echo "✅ Deployment completado!"
echo ""
echo "💡 Para ver los IPs externos:"
echo "   kubectl get svc proxy-client -n dev"
echo "   kubectl get svc service-discovery -n dev"
