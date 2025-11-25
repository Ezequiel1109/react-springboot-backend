<#
.SYNOPSIS
    Script principal para gestionar Docker (build, run, push, etc.)

.DESCRIPTION
    Permite construir, ejecutar, detener y subir imágenes Docker
    para diferentes entornos (prod, dev, test)

.PARAMETER Environment
    Entorno objetivo: prod, dev, test

.PARAMETER Action
    Acción a ejecutar: build, run, push, build-run, build-push, stop, logs, clean

.EXAMPLE
    .\docker-manager.ps1 -Environment prod -Action build
    .\docker-manager.ps1 -Environment dev -Action build-run
    .\docker-manager.ps1 -Environment test -Action build-run
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet('build', 'run', 'push', 'build-run', 'build-push', 'stop', 'logs', 'clean')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

# ============================================
# Configuración
# ============================================
$ImageName = "springboot-products"
$ContainerName = "springboot-${Environment}"
$Registry = "acrspringbootproducts.azurecr.io"  # Cambiar por tu ACR

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'Green')
    Write-Host $Message -ForegroundColor $Color
}

function Get-DockerfilePath {
    switch ($Environment) {
        'prod' { return Join-Path $PSScriptRoot "Dockerfile" }
        'dev' { return Join-Path $PSScriptRoot "Dockerfile.dev" }
        'test' { return Join-Path $PSScriptRoot "Dockerfile.test" }
    }
}

function Test-DockerRunning {
    try {
        docker ps | Out-Null
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker no está corriendo. Por favor, inicia Docker Desktop e intenta de nuevo." -Color Red
        return $false
    }
}

# ============================================
# Build
# ===========================================
function New-DockerImage {
    Write-ColorOutput "`n🔨 Construyendo imagen ${ImageName}:${Environment}..." "Cyan"

    $dockerFile = Get-DockerfilePath

    if (-not (Test-Path $dockerFile)) {
        Write-ColorOutput "❌ Dockerfile no encontrado para el entorno '$Environment'." -Color Red
        Write-ColorOutput "ubicacion esperada: $(Get-Location)\$dockerFile" "Yellow"
        exit 1
    }   

    Write-ColorOutput "Usando Dockerfile: $dockerFile" "Blue"

    $tag = "${ImageName}:${Environment}"

    # Build
    docker build -f $dockerFile -t $tag .

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Imagen construida exitosamente: $tag" -Color Green
        # Muestra el tamaño de la imagen
        $size = docker images $tag --format "{{.Size}}"
        Write-ColorOutput "Tamaño de la imagen: $size" -Color Green
    }
    else {
        Write-ColorOutput "❌ Falló la construcción de la imagen." -Color Red
        exit 1
    }
}

# ============================================
# Ejecutar contenedor
# ============================================
function Start-DockerContainer {
    Write-ColorOutput "`n🚀 Ejecutando contenedor ${ContainerName}..." "Cyan"

    # verificar si la imagen existe
    $imageExists = docker images "${ImageName}:${Environment}" --format "{{.Repository}}"
    if (-not $imageExists) {
        Write-ColorOutput "⚠️  Imagen no encontrada. Construyendo primero..." "Yellow"
        New-DockerImage
    }

    # Detener contenedor existente si está corriendo
    $existing = docker ps -a -q -f name=$ContainerName
    if ($existing) {
        Write-ColorOutput "🛑 Deteniendo contenedor existente..." "Yellow"
        docker stop $ContainerName 2>$null | Out-Null
        docker rm $ContainerName 2>$null | Out-Null
    }
    
    $port = switch ($Environment) {
        "prod" { "9090" }
        "dev" { "9090" }
        "test" { "9091" }
    }

    
    if ($Environment -eq "test") {
        # Tests se ejecutan y el contenedor se detiene automáticamente
        Write-ColorOutput "🧪 Ejecutando tests..." "Yellow"
        docker run --rm --name $ContainerName "${ImageName}:${Environment}"
    }
    else {
        # Contenedor persistente para prod/dev
        docker run -d `
            --name $ContainerName `
            -p "${port}:9090" `
            -e SPRING_PROFILES_ACTIVE=$Environment `
            "${ImageName}:${Environment}"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Contenedor iniciado: $ContainerName" "Green"
            Write-ColorOutput "🌐 Puerto: $port" "Cyan"
            Write-ColorOutput "📍 Health check: http://localhost:${port}/actuator/health" "Cyan"
            
            Write-ColorOutput "`n💡 Comandos útiles:" "Yellow"
            Write-ColorOutput "   Ver logs:  docker logs -f $ContainerName" "Gray"
            Write-ColorOutput "   Detener:   docker stop $ContainerName" "Gray"
            Write-ColorOutput "   Eliminar:  docker rm $ContainerName" "Gray"
        }
        else {
            Write-ColorOutput "❌ Error al iniciar contenedor" "Red"
            exit 1
        }
    }
}

# ============================================
# Push
# ============================================
function Push-DockerImage {
    Write-ColorOutput "`n📤 Subiendo imagen a registry..." "Cyan"
    
    # Verificar autenticación con ACR
    Write-ColorOutput "🔐 Autenticando con Azure Container Registry..." "Yellow"
    az acr login --name $Registry.Split('.')[0]
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Error al autenticar con ACR" "Red"
        Write-ColorOutput "   Ejecuta: az acr login --name <tu-acr>" "Yellow"
        exit 1
    }
    
    $localTag = "${ImageName}:${Environment}"
    $remoteTag = "${Registry}/${ImageName}:${Environment}"
    $remoteLatest = "${Registry}/${ImageName}:latest"
    
    # Tag con versión de entorno
    Write-ColorOutput "🏷️  Taggeando: $remoteTag" "Gray"
    docker tag $localTag $remoteTag
    
    # Push con versión de entorno
    Write-ColorOutput "📤 Subiendo: $remoteTag" "Gray"
    docker push $remoteTag
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Imagen subida exitosamente" "Green"
        
        # Si es producción, también taggear como latest
        if ($Environment -eq "prod") {
            Write-ColorOutput "🏷️  Taggeando como latest: $remoteLatest" "Gray"
            docker tag $localTag $remoteLatest
            docker push $remoteLatest
            Write-ColorOutput "✅ También subida como :latest" "Green"
        }
        
        Write-ColorOutput "`n📍 Imagen disponible en:" "Cyan"
        Write-ColorOutput "   $remoteTag" "White"
        if ($Environment -eq "prod") {
            Write-ColorOutput "   $remoteLatest" "White"
        }
    }
    else {
        Write-ColorOutput "❌ Error al subir imagen" "Red"
        exit 1
    }
}

# ============================================
# Stop
# ============================================
function Stop-DockerContainer {
    Write-ColorOutput "`n🛑 Deteniendo contenedor $ContainerName..." "Cyan"
    
    $running = docker ps -q -f name=$ContainerName
    if ($running) {
        docker stop $ContainerName
        docker rm $ContainerName
        Write-ColorOutput "✅ Contenedor detenido y eliminado" "Green"
    }
    else {
        Write-ColorOutput "ℹ️  El contenedor no está corriendo" "Yellow"
    }
}

# ============================================
# Logs
# ============================================
function Show-DockerLogs {
    Write-ColorOutput "`n📝 Logs del contenedor $ContainerName..." "Cyan"
    
    $exists = docker ps -a -q -f name=$ContainerName
    if (-not $exists) {
        Write-ColorOutput "❌ Contenedor no encontrado" "Red"
        exit 1
    }
    
    Write-ColorOutput "💡 Presiona Ctrl+C para salir" "Yellow"
    Start-Sleep -Seconds 1
    docker logs -f $ContainerName
}

# ============================================
# Clean
# ============================================
function Clear-DockerResources {
    Write-ColorOutput "`n🧹 Limpiando recursos de $Environment..." "Cyan"
    
    # Detener y eliminar contenedor
    $container = docker ps -a -q -f name=$ContainerName
    if ($container) {
        Write-ColorOutput "🛑 Deteniendo contenedor..." "Yellow"
        docker stop $ContainerName 2>$null | Out-Null
        docker rm $ContainerName 2>$null | Out-Null
    }
    
    # Eliminar imagen
    $image = docker images -q "${ImageName}:${Environment}"
    if ($image) {
        Write-ColorOutput "🗑️  Eliminando imagen..." "Yellow"
        docker rmi "${ImageName}:${Environment}" 2>$null | Out-Null
    }
    
    Write-ColorOutput "✅ Recursos limpiados" "Green"
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🐳 Docker Manager - Entorno: $Environment" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Verificar Docker
if (-not (Test-DockerRunning)) {
    exit 1
}

# Ejecutar acción
switch ($Action) {
    "build" { New-DockerImage }
    "run" { Start-DockerContainer }
    "push" { Push-DockerImage }
    "build-run" { 
        New-DockerImage
        Start-DockerContainer
    }
    "build-push" { 
        New-DockerImage
        Push-DockerImage
    }
    "stop" { Stop-DockerContainer }
    "logs" { Show-DockerLogs }
    "clean" { Clear-DockerResources }
}

Write-ColorOutput "`n✅ Operación completada exitosamente" "Green"
Write-ColorOutput "=" * 70 "Gray"