<#
.SYNOPSIS
    Despliega la aplicación en Azure Kubernetes Service (AKS)

.DESCRIPTION
    Script completo para desplegar en Azure AKS.
    Maneja autenticación, build, push a ACR y despliegue.

.PARAMETER ResourceGroup
    Nombre del Resource Group de Azure

.PARAMETER ClusterName
    Nombre del cluster AKS

.PARAMETER ACRName
    Nombre del Azure Container Registry

.EXAMPLE
    .\deploy-aks.ps1
    .\deploy-aks.ps1 -ResourceGroup "mi-rg" -ClusterName "mi-aks" -ACRName "miacr"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-springboot-products",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "aks-springboot-products",
    
    [Parameter(Mandatory=$false)]
    [string]$ACRName = "acrspringbootproducts"
)

$ErrorActionPreference = "Stop"

$NAMESPACE = "springboot-products"
$K8S_PATH = "..\..\K8s"

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
        Write-ColorOutput "❌ Azure CLI no está instalado" "Red"
        Write-ColorOutput "   Descarga desde: https://aka.ms/installazurecliwindows" "Yellow"
        return $false
    }
}

function Test-AzureLogin {
    $account = az account show 2>$null
    if (-not $account) {
        Write-ColorOutput "⚠️  No estás autenticado en Azure" "Yellow"
        Write-ColorOutput "🔐 Iniciando sesión..." "Cyan"
        az login
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Error al iniciar sesión" "Red"
            exit 1
        }
    }
    
    $accountInfo = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
    Write-ColorOutput "✅ Autenticado como: $($accountInfo.name)" "Green"
}

# ============================================
# Main
# ============================================
Write-ColorOutput "☁️  Desplegando en Azure Kubernetes Service (AKS)" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n📋 Configuración:" "Yellow"
Write-ColorOutput "   Resource Group: $ResourceGroup" "White"
Write-ColorOutput "   Cluster AKS:    $ClusterName" "White"
Write-ColorOutput "   ACR:            $ACRName" "White"

# Verificar requisitos
if (-not (Test-AzureCLI)) {
    exit 1
}

Test-AzureLogin

# ============================================
# Paso 1: Verificar recursos de Azure
# ============================================
Write-ColorOutput "`n🔍 Paso 1/7: Verificando recursos en Azure..." "Green"

$resourceGroupExists = az group exists --name $ResourceGroup
if ($resourceGroupExists -eq "false") {
    Write-ColorOutput "❌ Resource Group '$ResourceGroup' no existe" "Red"
    Write-ColorOutput "💡 Créalo primero con el script de setup" "Yellow"
    exit 1
}

$aksExists = az aks show --resource-group $ResourceGroup --name $ClusterName 2>$null
if (-not $aksExists) {
    Write-ColorOutput "❌ Cluster AKS '$ClusterName' no existe" "Red"
    Write-ColorOutput "💡 Créalo primero con el script de setup" "Yellow"
    exit 1
}

Write-ColorOutput "✅ Recursos verificados" "Green"

# ============================================
# Paso 2: Obtener credenciales de AKS
# ============================================
Write-ColorOutput "`n🔑 Paso 2/7: Obteniendo credenciales de AKS..." "Green"

az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al obtener credenciales" "Red"
    exit 1
}

$currentContext = kubectl config current-context
Write-ColorOutput "✅ Credenciales obtenidas. Contexto: $currentContext" "Green"

# ============================================
# Paso 3: Construir imagen Docker
# ============================================
Write-ColorOutput "`n🔨 Paso 3/7: Construyendo imagen Docker..." "Green"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$version = "v1.0.$timestamp"

docker build -t springboot-products:$version .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al construir imagen" "Red"
    exit 1
}

$imageSize = docker images "springboot-products:$version" --format "{{.Size}}"
Write-ColorOutput "✅ Imagen construida: springboot-products:$version ($imageSize)" "Green"

# ============================================
# Paso 4: Subir imagen a ACR
# ============================================
Write-ColorOutput "`n📤 Paso 4/7: Subiendo imagen a Azure Container Registry..." "Green"

# Autenticar con ACR
Write-ColorOutput "🔐 Autenticando con ACR..." "Yellow"
az acr login --name $ACRName

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al autenticar con ACR" "Red"
    exit 1
}

# Obtener servidor ACR
$acrServer = az acr show --name $ACRName --query loginServer --output tsv
Write-ColorOutput "📍 ACR Server: $acrServer" "Gray"

# Tag y push
$remoteTag = "${acrServer}/springboot-products:${version}"
$remoteLatest = "${acrServer}/springboot-products:latest"

Write-ColorOutput "🏷️  Taggeando imagen..." "Yellow"
docker tag "springboot-products:$version" $remoteTag
docker tag "springboot-products:$version" $remoteLatest

Write-ColorOutput "📤 Subiendo imagen..." "Yellow"
docker push $remoteTag
docker push $remoteLatest

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "✅ Imagen subida exitosamente" "Green"
    Write-ColorOutput "   $remoteTag" "Gray"
    Write-ColorOutput "   $remoteLatest" "Gray"
} else {
    Write-ColorOutput "❌ Error al subir imagen" "Red"
    exit 1
}

# ============================================
# Paso 5: Aplicar configuración base
# ============================================
Write-ColorOutput "`n📦 Paso 5/7: Aplicando configuración base..." "Green"

kubectl apply -f "$K8S_PATH\base\namespace.yaml"
kubectl apply -f "$K8S_PATH\base\configmap.yaml"

# Verificar secrets
if (Test-Path "$K8S_PATH\base\secrets.yaml") {
    kubectl apply -f "$K8S_PATH\base\secrets.yaml"
    Write-ColorOutput "✅ Configuración base aplicada" "Green"
} else {
    Write-ColorOutput "⚠️  secrets.yaml no encontrado. Generando..." "Yellow"
    & "..\generate-secrets.ps1"
    kubectl apply -f "$K8S_PATH\base\secrets.yaml"
}

# ============================================
# Paso 6: Desplegar MySQL y Backend
# ============================================
Write-ColorOutput "`n🗄️  Paso 6/7: Desplegando base de datos y backend..." "Green"

# MySQL
Write-ColorOutput "📊 Desplegando MySQL..." "Cyan"
kubectl apply -f "$K8S_PATH\mysql\"

Write-ColorOutput "⏳ Esperando MySQL..." "Yellow"
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error desplegando MySQL" "Red"
    exit 1
}

# Backend
Write-ColorOutput "📊 Desplegando Backend..." "Cyan"
kubectl apply -f "$K8S_PATH\azure\backend-deployment-aks.yaml"
kubectl apply -f "$K8S_PATH\backend-service.yaml"

Write-ColorOutput "⏳ Esperando Backend..." "Yellow"
kubectl wait --for=condition=ready pod -l app=backend-products -n $NAMESPACE --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error desplegando Backend" "Red"
    exit 1
}

# Ingress y HPA
Write-ColorOutput "📊 Aplicando Ingress y HPA..." "Cyan"
kubectl apply -f "$K8S_PATH\ingress.yaml"
kubectl apply -f "$K8S_PATH\hpa.yaml"

Write-ColorOutput "✅ Aplicación desplegada" "Green"

# ============================================
# Paso 7: Obtener información de acceso
# ============================================
Write-ColorOutput "`n🌐 Paso 7/7: Obteniendo información de acceso..." "Green"

Write-ColorOutput "`n📊 Estado del despliegue:" "Cyan"
kubectl get pods,svc,ingress,hpa -n $NAMESPACE

# Obtener IP del Ingress
Write-ColorOutput "`n⏳ Obteniendo IP pública del Ingress..." "Yellow"
Start-Sleep -Seconds 5

$ingressIP = kubectl get ingress backend-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null

if ($ingressIP) {
    Write-ColorOutput "✅ IP pública del Ingress: $ingressIP" "Green"
} else {
    Write-ColorOutput "⚠️  IP del Ingress aún no disponible (puede tardar 2-3 minutos)" "Yellow"
    Write-ColorOutput "   Ejecuta: kubectl get ingress -n $NAMESPACE -w" "White"
}

# ============================================
# Resumen final
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "✅ DESPLIEGUE EN AKS COMPLETADO" "Green"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n📋 Información del despliegue:" "Cyan"
Write-ColorOutput "   Versión:     $version" "White"
Write-ColorOutput "   Imagen ACR:  $remoteTag" "White"
Write-ColorOutput "   Namespace:   $NAMESPACE" "White"
if ($ingressIP) {
    Write-ColorOutput "   IP pública:  $ingressIP" "White"
}

Write-ColorOutput "`n🌐 Acceso a la aplicación:" "Cyan"
if ($ingressIP) {
    Write-ColorOutput "   http://$ingressIP/actuator/health" "Yellow"
    Write-ColorOutput "`n💡 Configura tu DNS A record:" "Cyan"
    Write-ColorOutput "   api.tudominio.com → $ingressIP" "White"
} else {
    Write-ColorOutput "   Esperando IP pública del Ingress..." "Yellow"
    Write-ColorOutput "   kubectl get ingress -n $NAMESPACE" "White"
}

Write-ColorOutput "`n📝 Ver logs:" "Cyan"
Write-ColorOutput "   kubectl logs -f deployment/backend-products -n $NAMESPACE" "White"

Write-ColorOutput "`n📊 Monitoreo en Azure Portal:" "Cyan"
Write-ColorOutput "   https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName" "Gray"

Write-ColorOutput "`n"