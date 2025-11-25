#!/bin/bash
# scripts/deploy-k8s.sh
# Script para desplegar todos los recursos en Kubernetes

set -e

NAMESPACE="springboot-products"

echo "☸️  Desplegando en Kubernetes..."

# Crear namespace
echo "📦 Creando namespace..."
kubectl apply -f k8s/namespace.yaml

# Aplicar ConfigMap y Secrets
echo "🔧 Aplicando ConfigMap..."
kubectl apply -f k8s/configmap.yaml

echo "🔐 Aplicando Secrets..."
kubectl apply -f k8s/secrets.yaml

# Desplegar MySQL
echo "🗄️  Desplegando MySQL..."
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

# Esperar a que MySQL esté listo
echo "⏳ Esperando a que MySQL esté listo..."
kubectl wait --for=condition=ready pod -l app=mysql -n ${NAMESPACE} --timeout=300s

# Desplegar Backend
echo "🚀 Desplegando Backend..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Esperar a que Backend esté listo
echo "⏳ Esperando a que Backend esté listo..."
kubectl wait --for=condition=ready pod -l app=backend-products -n ${NAMESPACE} --timeout=300s

# Aplicar Ingress
echo "🌐 Configurando Ingress..."
kubectl apply -f k8s/ingress.yaml

# Aplicar HPA
echo "📈 Configurando HorizontalPodAutoscaler..."
kubectl apply -f k8s/hpa.yaml

echo ""
echo "✅ Despliegue completado!"
echo ""
echo "📊 Estado de los pods:"
kubectl get pods -n ${NAMESPACE}
echo ""
echo "🌐 Servicios:"
kubectl get svc -n ${NAMESPACE}
echo ""
echo "🔗 Ingress:"
kubectl get ingress -n ${NAMESPACE}