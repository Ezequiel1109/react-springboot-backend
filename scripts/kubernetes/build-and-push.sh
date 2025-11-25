#!/bin/bash
# scripts/build-and-push.sh
# Script para construir y subir la imagen Docker

set -e  # Salir si hay algún error

# Variables
DOCKER_USERNAME="ezequielrd"
IMAGE_NAME="springboot-products"
TAG="latest"

echo "🔨 Construyendo imagen Docker..."
docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} .

echo "📦 Taggeando imagen..."
docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:$(date +%Y%m%d-%H%M%S)

echo "🚀 Subiendo imagen a Docker Hub..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:$(date +%Y%m%d-%H%M%S)

echo "✅ Imagen subida exitosamente!"
echo "   ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"