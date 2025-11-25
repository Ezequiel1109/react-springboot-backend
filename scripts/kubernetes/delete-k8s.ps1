<#
.SYNOPSIS
    Elimina todos los recursos de Kubernetes del proyecto

.DESCRIPTION
    Script para eliminar completamente el despliegue de Kubernetes.
    Puede eliminar todo el namespace o recursos específicos.

.PARAMETER DeleteNamespace
    Si se especifica, elimina todo el namespace (elimina todo)

.PARAMETER DeleteBackend
    Si se especifica, elimina solo el backend

.PARAMETER DeleteMySQL
    Si se especifica, elimina solo MySQL

.EXAMPLE
    .\delete-k8s.ps1
    .\delete-k8s.ps1 -DeleteNamespace
    .\delete-k8s.ps1 -DeleteBackend
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DeleteNamespace,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteBackend,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteMySQL
)

$ErrorActionPreference = "Stop"

$NAMESPACE = "springboot-products"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Confirm-Action($message) {
    Write-ColorOutput "`n⚠️  $message" "Yellow"
    $response = Read-Host "¿Estás seguro? (y/n)"
    return ($response -eq "y" -or $response -eq "Y")
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🗑️  Eliminar recursos de Kubernetes" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Verificar kubectl
try {
    kubectl version --client --short | Out-Null
} catch {
    Write-ColorOutput "❌ kubectl no está disponible" "Red"
    exit 1
}

# Mostrar recursos actuales
Write-ColorOutput "`n📊 Recursos actuales en namespace '$NAMESPACE':" "Cyan"
kubectl get all -n $NAMESPACE 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "`nℹ️  No hay recursos en el namespace (o no existe)" "Yellow"
    exit 0
}

# ============================================
# Eliminar todo el namespace
# ============================================
if ($DeleteNamespace) {
    
    if (Confirm-Action "Esto eliminará TODOS los recursos del namespace '$NAMESPACE'") {
        
        Write-ColorOutput "`n🗑️  Eliminando namespace completo..." "Red"
        
        kubectl delete namespace $NAMESPACE
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Namespace '$NAMESPACE' eliminado" "Green"
            Write-ColorOutput "`n💡 Para volver a desplegar:" "Cyan"
            Write-ColorOutput "   ..\deploy-local.ps1" "White"
        } else {
            Write-ColorOutput "❌ Error al eliminar namespace" "Red"
        }
        
    } else {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
    }
    
    exit 0
}

# ============================================
# Eliminar solo Backend
# ============================================
if ($DeleteBackend) {
    
    if (Confirm-Action "Esto eliminará el deployment del Backend") {
        
        Write-ColorOutput "`n🗑️  Eliminando Backend..." "Yellow"
        
        kubectl delete deployment backend-products -n $NAMESPACE
        kubectl delete service backend-service -n $NAMESPACE
        kubectl delete hpa backend-hpa -n $NAMESPACE 2>$null
        kubectl delete ingress backend-ingress -n $NAMESPACE 2>$null
        
        Write-ColorOutput "✅ Backend eliminado" "Green"
        
    } else {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
    }
    
    exit 0
}

# ============================================
# Eliminar solo MySQL
# ============================================
if ($DeleteMySQL) {
    
    if (Confirm-Action "Esto eliminará MySQL y sus datos (PersistentVolumeClaim)") {
        
        Write-ColorOutput "`n🗑️  Eliminando MySQL..." "Yellow"
        
        kubectl delete deployment mysql -n $NAMESPACE
        kubectl delete service mysql-service -n $NAMESPACE
        kubectl delete pvc mysql-pvc -n $NAMESPACE
        
        Write-ColorOutput "✅ MySQL eliminado" "Green"
        Write-ColorOutput "⚠️  Los datos en el PersistentVolume se han perdido" "Red"
        
    } else {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
    }
    
    exit 0
}

# ============================================
# Menú interactivo (si no se pasó ningún parámetro)
# ============================================
Write-ColorOutput "`n🗑️  Opciones de eliminación:" "Cyan"
Write-ColorOutput "   1. Eliminar TODO (namespace completo)" "White"
Write-ColorOutput "   2. Eliminar solo Backend" "White"
Write-ColorOutput "   3. Eliminar solo MySQL" "White"
Write-ColorOutput "   4. Eliminar Backend + MySQL (mantener namespace)" "White"
Write-ColorOutput "   5. Cancelar" "White"

$choice = Read-Host "`nSelecciona opción (1-5)"

switch ($choice) {
    "1" {
        if (Confirm-Action "Eliminar TODOS los recursos del namespace") {
            Write-ColorOutput "`n🗑️  Eliminando namespace..." "Red"
            kubectl delete namespace $NAMESPACE
            Write-ColorOutput "✅ Eliminado" "Green"
        }
    }
    "2" {
        if (Confirm-Action "Eliminar solo Backend") {
            Write-ColorOutput "`n🗑️  Eliminando Backend..." "Yellow"
            kubectl delete deployment backend-products -n $NAMESPACE
            kubectl delete service backend-service -n $NAMESPACE
            kubectl delete hpa backend-hpa -n $NAMESPACE 2>$null
            kubectl delete ingress backend-ingress -n $NAMESPACE 2>$null
            Write-ColorOutput "✅ Backend eliminado" "Green"
        }
    }
    "3" {
        if (Confirm-Action "Eliminar MySQL (se perderán los datos)") {
            Write-ColorOutput "`n🗑️  Eliminando MySQL..." "Yellow"
            kubectl delete deployment mysql -n $NAMESPACE
            kubectl delete service mysql-service -n $NAMESPACE
            kubectl delete pvc mysql-pvc -n $NAMESPACE
            Write-ColorOutput "✅ MySQL eliminado" "Green"
        }
    }
    "4" {
        if (Confirm-Action "Eliminar Backend y MySQL") {
            Write-ColorOutput "`n🗑️  Eliminando Backend..." "Yellow"
            kubectl delete deployment backend-products -n $NAMESPACE
            kubectl delete service backend-service -n $NAMESPACE
            kubectl delete hpa backend-hpa -n $NAMESPACE 2>$null
            kubectl delete ingress backend-ingress -n $NAMESPACE 2>$null
            
            Write-ColorOutput "`n🗑️  Eliminando MySQL..." "Yellow"
            kubectl delete deployment mysql -n $NAMESPACE
            kubectl delete service mysql-service -n $NAMESPACE
            kubectl delete pvc mysql-pvc -n $NAMESPACE
            
            Write-ColorOutput "✅ Backend y MySQL eliminados" "Green"
        }
    }
    "5" {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
        exit 0
    }
    default {
        Write-ColorOutput "❌ Opción inválida" "Red"
        exit 1
    }
}

# ============================================
# Verificar estado final
# ============================================
Write-ColorOutput "`n📊 Estado final:" "Cyan"
kubectl get all -n $NAMESPACE 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "ℹ️  Namespace vacío o eliminado" "Yellow"
}

Write-ColorOutput "`n✅ Operación completada" "Green"