<#
.SYNOPSIS
    Script rápido para ejecutar la aplicación localmente en Docker

.DESCRIPTION
    Construye y ejecuta la aplicación en modo desarrollo con una sola instrucción

.EXAMPLE
    .\run-local.ps1
#>

$ErrorActionPreference = 'Stop'

function Write-ColorOutput($Message, $Color = 'Green') {
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "🚀 Construyendo y ejecutando la aplicación en modo local (dev)..."

# verificar si Docker está corriendo
try{
    docker ps | Out-Null
}catch{
    Write-ColorOutput "❌ Docker no está corriendo. Por favor, inicia Docker Desktop e inténtalo de nuevo." 'Red'
    exit 1
}

# Construir la imagen
Write-ColorOutput "`n🔨 Construyendo imagen..." "Green"
docker build -t springboot-products:local .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Falló la construcción de la imagen Docker." 'Red'
    exit 1
}

# detener el contenedor si existe
$existing = docker ps -a -q -f name=springboot-local
if ($existing) {
    Write-ColorOutput "`n🛑 Deteniendo contenedor existente..." "Yellow"
    docker stop springboot-local | Out-Null
    docker rm springboot-local | Out-Null
}

# Ejecutar el contenedor
Write-ColorOutput "`n🚀 Ejecutando contenedor..." "Green"
docker run -d `
    --name springboot-local `
    -p 9090:9090 `
    -e SPRING_PROFILES_ACTIVE=dev `
    -e SPRING_DATASOURCE_URL="jdbc:mysql://host.docker.internal:3306/db_backend_crud?useSSL=false" `
    -e SPRING_DATASOURCE_USERNAME=root `
    -e SPRING_DATASOURCE_PASSWORD=root `
    springboot-products:local
    
if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "`n✅ Aplicación iniciada" "Green"
    Write-ColorOutput "🌐 http://localhost:9090" "Cyan"
    Write-ColorOutput "❤️  http://localhost:9090/actuator/health" "Cyan"
    
    Write-ColorOutput "`n📝 Ver logs:" "Yellow"
    Write-ColorOutput "   docker logs -f springboot-local" "White"
    
    Write-ColorOutput "`n🛑 Detener:" "Yellow"
    Write-ColorOutput "   docker stop springboot-local" "White"
} else {
    Write-ColorOutput "❌ Error al iniciar contenedor" "Red"
    exit 1
}