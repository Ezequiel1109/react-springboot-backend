#!/bin/bash
# scripts/delete-k8s.sh
# Script para eliminar todos los recursos de Kubernetes

set -e

NAMESPACE="springboot-products"

echo "🗑️  Eliminando recursos de Kubernetes..."

echo "⚠️  Esta acción eliminará todos los recursos del namespace ${NAMESPACE}"
read -p "¿Estás seguro? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Operación cancelada"
    exit 0
fi

# Eliminar en orden inverso
kubectl delete -f k8s/hpa.yaml --ignore-not-found=true
kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/backend-service.yaml --ignore-not-found=true
kubectl delete -f k8s/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-service.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql-pvc.yaml --ignore-not-found=true
kubectl delete -f k8s/secrets.yaml --ignore-not-found=true
kubectl delete -f k8s/configmap.yaml --ignore-not-found=true

echo "🧹 Eliminando namespace..."
kubectl delete namespace ${NAMESPACE} --ignore-not-found=true

echo "✅ Recursos eliminados exitosamente!"