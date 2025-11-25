# Script simple para ejecutar tests con Testcontainers
param(
    [string]$TestClass = "*IT"
)

Write-Host "Ejecutando tests con Testcontainers..." -ForegroundColor Green

# Verificar Docker
try {
    docker version | Out-Null
    Write-Host "Docker esta funcionando correctamente" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker no esta ejecutandose" -ForegroundColor Red
    exit 1
}

# Ejecutar tests
Write-Host "Iniciando tests..." -ForegroundColor Yellow

if ($TestClass -eq "*IT") {
    cmd /c "mvnw.cmd test"
} else {
    cmd /c "mvnw.cmd test -Dtest=$TestClass"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Tests completados exitosamente!" -ForegroundColor Green
} else {
    Write-Host "Los tests fallaron" -ForegroundColor Red
    exit $LASTEXITCODE
}