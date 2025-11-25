<#
.SYNOPSIS
    Script para gestionar diferentes builds de Docker
.DESCRIPTION
    Permite construir imágenes Docker para diferentes entornos y configuraciones
.PARAMETER Environment
    Entorno de destino (dev, test, prod)
.PARAMETER BuildType
    Tipo de build (frontend, backend, full)
.PARAMETER Tag
    Tag personalizado para la imagen
.PARAMETER NoCacheFlag
    Forzar build sin usar caché
.EXAMPLE
    .\build-local.ps1 -Environment dev -BuildType backend
    .\build-local.ps1 -Environment prod -BuildType full -Tag v1.0.0 -NoCacheFlag
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'test', 'prod')]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('frontend', 'backend', 'full')]
    [string]$BuildType = 'backend',
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = 'latest',
    
    [Parameter(Mandatory=$false)]
    [switch]$NoCacheFlag
)

# Configuración
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$BackendPath = Join-Path $ProjectRoot "src"
$FrontendPath = Join-Path $ProjectRoot "react-frontend"

# Nombres de imágenes
$BackendImage = "react-springboot-backend"
$FrontendImage = "react-springboot-frontend"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'Green')
    Write-Host $Message -ForegroundColor $Color
}

function New-BackendImage {
    Write-ColorOutput "🔨 Construyendo imagen backend para entorno: $Environment" -Color Cyan
    
    $dockerFile = Join-Path $BackendPath "Dockerfile"
    $imageTag = "${BackendImage}:${Environment}-${Tag}"
    
    $buildArgs = @(
        "build",
        "-t", $imageTag,
        "-f", $dockerFile,
        "--build-arg", "ENVIRONMENT=$Environment"
    )
    
    if ($NoCacheFlag) {
        $buildArgs += "--no-cache"
    }
    
    $buildArgs += $BackendPath
    
    & docker $buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Backend construido exitosamente: $imageTag" -Color Green
    } else {
        throw "❌ Error al construir imagen backend"
    }
}

function New-FrontendImage {
    Write-ColorOutput "🔨 Construyendo imagen frontend para entorno: $Environment" -Color Cyan
    
    $dockerFile = Join-Path $FrontendPath "Dockerfile"
    $imageTag = "${FrontendImage}:${Environment}-${Tag}"
    
    $buildArgs = @(
        "build",
        "-t", $imageTag,
        "-f", $dockerFile,
        "--build-arg", "ENVIRONMENT=$Environment"
    )
    
    if ($NoCacheFlag) {
        $buildArgs += "--no-cache"
    }
    
    $buildArgs += $FrontendPath
    
    & docker $buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Frontend construido exitosamente: $imageTag" -Color Green
    } else {
        throw "❌ Error al construir imagen frontend"
    }
}

# Ejecución principal
try {
    Write-ColorOutput "🚀 Iniciando proceso de build Docker" -Color Magenta
    Write-ColorOutput "Entorno: $Environment | Tipo: $BuildType | Tag: $Tag" -Color Yellow
    
    switch ($BuildType) {
        'backend' {
            New-BackendImage
        }
        'frontend' {
            New-FrontendImage
        }
        'full' {
            New-BackendImage
            New-FrontendImage
        }
    }
    
    Write-ColorOutput "`n✨ Proceso completado exitosamente" -Color Green
    
    # Mostrar imágenes creadas
    Write-ColorOutput "`n📦 Imágenes disponibles:" -Color Cyan
    docker images | Select-String -Pattern "react-springboot"
    
} catch {
    Write-ColorOutput "`n❌ Error: $_" -Color Red
    exit 1
}