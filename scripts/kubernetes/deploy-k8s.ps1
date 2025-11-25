<#
.SYNOPSIS
    Script genérico de despliegue en Kubernetes

.DESCRIPTION
    Despliega la aplicación en Kubernetes (detecta automáticamente el contexto).
    Funciona tanto para Docker Desktop como para AKS.

.EXAMPLE
    .\deploy-k8s.ps1
#>

$ErrorActionPreference = "Stop"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Get-KubernetesContext {
    $context = kubectl config current-context
    return $context
}

# ============================================
# Main
# ============================================
Write-ColorOutput "☸️  Despliegue genérico en Kubernetes" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Detectar contexto
$context = Get-KubernetesContext
Write-ColorOutput "`n📍 Contexto detectado: $context" "Yellow"

if ($context -eq "docker-desktop") {
    Write-ColorOutput "🐳 Redirigiendo a deploy-local.ps1..." "Cyan"
    & "$PSScriptRoot\deploy-local.ps1"
} elseif ($context -match "aks-") {
    Write-ColorOutput "☁️  Redirigiendo a deploy-aks.ps1..." "Cyan"
    & "$PSScriptRoot\deploy-aks.ps1"
} else {
    Write-ColorOutput "⚠️  Contexto desconocido: $context" "Yellow"
    Write-ColorOutput "`n¿Qué despliegue quieres usar?" "Cyan"
    Write-ColorOutput "   1. Docker Desktop (local)" "White"
    Write-ColorOutput "   2. Azure AKS" "White"
    
    $choice = Read-Host "Selecciona opción (1-2)"
    
    switch ($choice) {
        "1" { & "$PSScriptRoot\deploy-local.ps1" }
        "2" { & "$PSScriptRoot\deploy-aks.ps1" }
        default {
            Write-ColorOutput "❌ Opción inválida" "Red"
            exit 1
        }
    }
}