<#
.SYNOPSIS
    Construye la imagen Docker y la sube a Azure Container Registry

.DESCRIPTION
    Script completo para:
    1. Construir imagen Docker
    2. Autenticar con Azure Container Registry
    3. Taggear imagen con versión
    4. Subir a ACR

.PARAMETER ACRName
    Nombre del Azure Container Registry

.PARAMETER Tag
    Tag para la imagen (por defecto: timestamp)

.EXAMPLE
    .\build-and-push.ps1
    .\build-and-push.ps1 -ACRName "miacr" -Tag "v1.0.0"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ACRName = "acrspringbootproducts",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = ""
)

$ErrorActionPreference = "Stop"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Test-AzureCLI {
    try {
        az version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-DockerRunning {
    try {
        docker ps | Out-Null
        return $true
    } catch {
        return $false
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🏗️  Build and Push to Azure Container Registry" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Verificar requisitos
Write-ColorOutput "`n🔍 Verificando requisitos..." "Green"

if (-not (Test-DockerRunning)) {
    Write-ColorOutput "❌ Docker no está corriendo" "Red"
    Write-ColorOutput "   Inicia Docker Desktop" "Yellow"
    exit 1
}
Write-ColorOutput "✅ Docker está corriendo" "Green"

if (-not (Test-AzureCLI)) {
    Write-ColorOutput "❌ Azure CLI no está instalado" "Red"
    Write-ColorOutput "   Descarga: https://aka.ms/installazurecliwindows" "Yellow"
    exit 1
}
Write-ColorOutput "✅ Azure CLI está instalado" "Green"

# Verificar autenticación Azure
$account = az account show 2>$null
if (-not $account) {
    Write-ColorOutput "⚠️  No estás autenticado en Azure" "Yellow"
    az login
}

$accountInfo = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
Write-ColorOutput "✅ Autenticado en Azure: $($accountInfo.name)" "Green"

# ============================================
# Generar tag si no se proporcionó
# ============================================
if ([string]::IsNullOrWhiteSpace($Tag)) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Tag = "v1.0.$timestamp"
    Write-ColorOutput "🏷️  Tag generado: $Tag" "Yellow"
} else {
    Write-ColorOutput "🏷️  Usando tag: $Tag" "Cyan"
}

# ============================================
# Paso 1: Construir imagen
# ============================================
Write-ColorOutput "`n🔨 Paso 1/4: Construyendo imagen Docker..." "Green"

$imageName = "springboot-products"
$localTag = "${imageName}:${Tag}"

docker build -t $localTag .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al construir imagen" "Red"
    exit 1
}

$imageSize = docker images $localTag --format "{{.Size}}"
Write-ColorOutput "✅ Imagen construida: $localTag ($imageSize)" "Green"

# ============================================
# Paso 2: Autenticar con ACR
# ============================================
Write-ColorOutput "`n🔐 Paso 2/4: Autenticando con Azure Container Registry..." "Green"

az acr login --name $ACRName

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al autenticar con ACR" "Red"
    Write-ColorOutput "   Verifica que el ACR '$ACRName' existe" "Yellow"
    Write-ColorOutput "   az acr list --output table" "Gray"
    exit 1
}

Write-ColorOutput "✅ Autenticado con ACR: $ACRName" "Green"

# ============================================
# Paso 3: Taggear imagen
# ============================================
Write-ColorOutput "`n🏷️  Paso 3/4: Taggeando imagen para ACR..." "Green"

$acrServer = az acr show --name $ACRName --query loginServer --output tsv
$remoteTag = "${acrServer}/${imageName}:${Tag}"
$remoteLatest = "${acrServer}/${imageName}:latest"

Write-ColorOutput "📍 ACR Server: $acrServer" "Gray"

docker tag $localTag $remoteTag
Write-ColorOutput "✅ Tagged: $remoteTag" "Green"

# Si es una versión de producción, también taggear como latest
if ($Tag -match "^v\d+\.\d+\.\d+$") {
    docker tag $localTag $remoteLatest
    Write-ColorOutput "✅ Tagged: $remoteLatest" "Green"
}

# ============================================
# Paso 4: Push a ACR
# ============================================
Write-ColorOutput "`n📤 Paso 4/4: Subiendo imagen a ACR..." "Green"

# Push tag específico
Write-ColorOutput "📤 Subiendo: $remoteTag" "Cyan"
docker push $remoteTag

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al subir imagen" "Red"
    exit 1
}

Write-ColorOutput "✅ Subida exitosa: $remoteTag" "Green"

# Push latest si aplica
if ($Tag -match "^v\d+\.\d+\.\d+$") {
    Write-ColorOutput "📤 Subiendo: $remoteLatest" "Cyan"
    docker push $remoteLatest
    Write-ColorOutput "✅ Subida exitosa: $remoteLatest" "Green"
}

# ============================================
# Resumen
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "✅ BUILD AND PUSH COMPLETADO" "Green"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n📊 Resumen:" "Cyan"
Write-ColorOutput "   ACR:         $ACRName" "White"
Write-ColorOutput "   Imagen:      $imageName" "White"
Write-ColorOutput "   Tag:         $Tag" "White"
Write-ColorOutput "   Tamaño:      $imageSize" "White"

Write-ColorOutput "`n🌐 Imagen disponible en:" "Cyan"
Write-ColorOutput "   $remoteTag" "Yellow"
if ($Tag -match "^v\d+\.\d+\.\d+$") {
    Write-ColorOutput "   $remoteLatest" "Yellow"
}

Write-ColorOutput "`n💡 Próximos pasos:" "Cyan"
Write-ColorOutput "   1. Desplegar en Kubernetes:" "White"
Write-ColorOutput "      ..\deploy-aks.ps1" "Gray"
Write-ColorOutput "   2. Ver imágenes en ACR:" "White"
Write-ColorOutput "      az acr repository show-tags --name $ACRName --repository $imageName --output table" "Gray"
Write-ColorOutput "   3. Actualizar deployment en K8s con esta imagen:" "White"
Write-ColorOutput "      kubectl set image deployment/backend-products backend=$remoteTag -n springboot-products" "Gray"

Write-ColorOutput "`n📚 Documentación:" "Cyan"
Write-ColorOutput "   - ACR: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ContainerRegistry%2Fregistries" "Gray"

Write-ColorOutput "`n"