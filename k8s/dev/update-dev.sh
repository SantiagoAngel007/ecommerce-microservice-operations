#!/bin/bash

echo "Actualizando manifiestos de dev..."

# Servicios a actualizar
SERVICES="service-discovery proxy-client user-service product-service order-service payment-service favourite-service shipping-service config-server"

for service in $SERVICES; do
    if [ -d "$service" ]; then
        echo "Actualizando $service..."
        
        # Actualizar namespace en deployment
        if [ -f "$service/deployment.yaml" ]; then
            sed -i 's/namespace: stage/namespace: dev/g' "$service/deployment.yaml"
            echo "  ✓ Deployment namespace actualizado"
        fi
        
        # Actualizar namespace en configmap
        if [ -f "$service/configmap.yaml" ]; then
            sed -i 's/namespace: stage/namespace: dev/g' "$service/configmap.yaml"
            # Actualizar referencias a application-stage.yml -> application-dev.yml
            sed -i 's/application-stage\.yml/application-dev.yml/g' "$service/configmap.yaml"
            # Actualizar perfil activo
            sed -i 's/active: stage/active: dev/g' "$service/configmap.yaml"
            # Actualizar nombre de base de datos
            sed -i 's/ecommerce_stage_db/ecommerce_dev_db/g' "$service/configmap.yaml"
            echo "  ✓ ConfigMap namespace actualizado"
        fi
        
        # Actualizar namespace en service
        if [ -f "$service/service.yaml" ]; then
            sed -i 's/namespace: stage/namespace: dev/g' "$service/service.yaml"
            echo "  ✓ Service namespace actualizado"
        fi
    fi
done

# Actualizar Zipkin
if [ -d "zipkin" ]; then
    echo "Actualizando zipkin..."
    if [ -f "zipkin/deployment.yaml" ]; then
        sed -i 's/namespace: stage/namespace: dev/g' "zipkin/deployment.yaml"
    fi
    if [ -f "zipkin/service.yaml" ]; then
        sed -i 's/namespace: stage/namespace: dev/g' "zipkin/service.yaml"
    fi
    echo "  ✓ Zipkin actualizado"
fi

# Actualizar secrets
if [ -d "secrets" ]; then
    echo "Actualizando secrets..."
    if [ -f "secrets/dockerhub-credentials-secret.yaml" ]; then
        sed -i 's/namespace: stage/namespace: dev/g' "secrets/dockerhub-credentials-secret.yaml"
    fi
    echo "  ✓ Secrets actualizado"
fi

echo "✓ Todos los manifiestos de dev actualizados"
