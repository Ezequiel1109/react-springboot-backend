# Script para ejecutar tests con Docker
# Uso: .\run-tests-docker.ps1 [tipo-test]
# Tipos: unit, integration, all

param(
    [Parameter(Position=0)]
    [string]$TestType = "all"
)

Write-Host "🐳 Ejecutando tests con Docker..." -ForegroundColor Blue

# Verificar si Docker está ejecutándose
try {
    docker version | Out-Null
} catch {
    Write-Host "❌ Error: Docker no está ejecutándose. Por favor inicia Docker Desktop." -ForegroundColor Red
    exit 1
}

switch ($TestType.ToLower()) {
    "unit" {
        Write-Host "🔧 Ejecutando tests unitarios..." -ForegroundColor Green
        docker build -f Dockerfile.test -t backend-test .
        docker run --rm -v "${PWD}/target:/app/target" backend-test mvn test -Dtest="*Test"
    }
    "integration" {
        Write-Host "🔗 Ejecutando tests de integración..." -ForegroundColor Green
        docker build -f Dockerfile.test -t backend-test .
        docker run --rm -v "${PWD}/target:/app/target" backend-test mvn test -Dtest="*IT"
    }
    "all" {
        Write-Host "🚀 Ejecutando todos los tests..." -ForegroundColor Green
        docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
        docker-compose -f docker-compose.test.yml down -v
    }
    "testcontainers" {
        Write-Host "📦 Ejecutando tests con Testcontainers..." -ForegroundColor Green
        # Montar el socket de Docker para Testcontainers
        docker run --rm `
            -v "${PWD}:/app" `
            -v "/var/run/docker.sock:/var/run/docker.sock" `
            -w /app `
            openjdk:21-jdk-slim `
            bash -c "apt-get update && apt-get install -y maven && mvn test"
    }
    default {
        Write-Host "❌ Tipo de test no válido: $TestType" -ForegroundColor Red
        Write-Host "Tipos válidos: unit, integration, all, testcontainers" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Tests completados!" -ForegroundColor Green