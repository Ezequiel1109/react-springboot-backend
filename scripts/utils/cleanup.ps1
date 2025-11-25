<#
.SYNOPSIS
    Limpia recursos de Docker y Kubernetes del proyecto

.DESCRIPTION
    Script completo para limpiar:
    - Contenedores Docker
    - Imágenes Docker
    - Volúmenes Docker
    - Recursos de Kubernetes
    - Archivos temporales

.PARAMETER All
    Limpia todo (Docker + Kubernetes + archivos temporales)

.PARAMETER Docker
    Limpia solo recursos de Docker

.PARAMETER Kubernetes
    Limpia solo recursos de Kubernetes

.PARAMETER TempFiles
    Limpia solo archivos temporales

.EXAMPLE
    .\cleanup.ps1 -All
    .\cleanup.ps1 -Docker
    .\cleanup.ps1 -Kubernetes
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$All,
    
    [Parameter(Mandatory=$false)]
    [switch]$Docker,
    
    [Parameter(Mandatory=$false)]
    [switch]$Kubernetes,
    
    [Parameter(Mandatory=$false)]
    [switch]$TempFiles
)

$ErrorActionPreference = "Continue"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Confirm-Action($message) {
    Write-ColorOutput "`n⚠️  $message" "Yellow"
    $response = Read-Host "¿Continuar? (y/n)"
    return ($response -eq "y" -or $response -eq "Y")
}

function Get-DockerResources {
    Write-ColorOutput "`n📊 Recursos actuales de Docker:" "Cyan"
    
    $containers = docker ps -a --filter "name=springboot" --format "{{.Names}}" 2>$null
    $images = docker images "springboot-products" --format "{{.Repository}}:{{.Tag}}" 2>$null
    $volumes = docker volume ls --filter "name=springboot" --format "{{.Name}}" 2>$null
    
    if ($containers) {
        Write-ColorOutput "🐳 Contenedores:" "Yellow"
        $containers | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    }
    
    if ($images) {
        Write-ColorOutput "📦 Imágenes:" "Yellow"
        $images | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    }
    
    if ($volumes) {
        Write-ColorOutput "💾 Volúmenes:" "Yellow"
        $volumes | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    }
    
    if (-not $containers -and -not $images -and -not $volumes) {
        Write-ColorOutput "✅ No hay recursos de Docker para limpiar" "Green"
        return $false
    }
    
    return $true
}

function Get-KubernetesResources {
    Write-ColorOutput "`n📊 Recursos actuales de Kubernetes:" "Cyan"
    
    $namespace = "springboot-products"
    kubectl get all -n $namespace 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "✅ No hay recursos de Kubernetes para limpiar" "Green"
        return $false
    }
    
    return $true
}

# ============================================
# Limpieza de Docker
# ============================================
function Clear-DockerResources {
    Write-ColorOutput "`n🐳 Limpiando recursos de Docker..." "Cyan"
    Write-ColorOutput "=" * 70 "Gray"
    
    # Verificar Docker
    try {
        docker ps | Out-Null
    } catch {
        Write-ColorOutput "⚠️  Docker no está corriendo" "Yellow"
        return
    }
    
    if (-not (Get-DockerResources)) {
        return
    }
    
    if (-not (Confirm-Action "Esto detendrá y eliminará contenedores, imágenes y volúmenes del proyecto")) {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
        return
    }
    
    # Detener y eliminar contenedores
    Write-ColorOutput "`n🛑 Deteniendo contenedores..." "Yellow"
    $containers = docker ps -a --filter "name=springboot" -q
    if ($containers) {
        docker stop $containers 2>$null | Out-Null
        docker rm $containers 2>$null | Out-Null
        Write-ColorOutput "✅ Contenedores eliminados" "Green"
    }
    
    # Eliminar imágenes
    Write-ColorOutput "`n🗑️  Eliminando imágenes..." "Yellow"
    $images = docker images "springboot-products" -q
    if ($images) {
        docker rmi -f $images 2>$null | Out-Null
        Write-ColorOutput "✅ Imágenes eliminadas" "Green"
    }
    
    # Eliminar volúmenes
    Write-ColorOutput "`n💾 Eliminando volúmenes..." "Yellow"
    $volumes = docker volume ls --filter "name=springboot" -q
    if ($volumes) {
        docker volume rm $volumes 2>$null | Out-Null
        Write-ColorOutput "✅ Volúmenes eliminados" "Green"
    }
    
    # Limpiar recursos no utilizados
    Write-ColorOutput "`n🧹 Limpiando recursos no utilizados..." "Yellow"
    docker system prune -f 2>$null | Out-Null
    Write-ColorOutput "✅ Limpieza de Docker completada" "Green"
}

# ============================================
# Limpieza de Kubernetes
# ============================================
function Clear-KubernetesResources {
    Write-ColorOutput "`n☸️  Limpiando recursos de Kubernetes..." "Cyan"
    Write-ColorOutput "=" * 70 "Gray"
    
    # Verificar kubectl
    try {
        kubectl version --client --short | Out-Null
    } catch {
        Write-ColorOutput "⚠️  kubectl no está disponible" "Yellow"
        return
    }
    
    if (-not (Get-KubernetesResources)) {
        return
    }
    
    if (-not (Confirm-Action "Esto eliminará el namespace 'springboot-products' y todos sus recursos")) {
        Write-ColorOutput "❌ Operación cancelada" "Yellow"
        return
    }
    
    $namespace = "springboot-products"
    
    Write-ColorOutput "`n🗑️  Eliminando namespace..." "Yellow"
    kubectl delete namespace $namespace --timeout=120s 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Recursos de Kubernetes eliminados" "Green"
    } else {
        Write-ColorOutput "⚠️  Error al eliminar algunos recursos" "Yellow"
    }
}

# ============================================
# Limpieza de archivos temporales
# ============================================
function Clear-TempFiles {
    Write-ColorOutput "`n📁 Limpiando archivos temporales..." "Cyan"
    Write-ColorOutput "=" * 70 "Gray"
    
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    
    $tempPatterns = @(
        "*.log",
        "*.tmp",
        "*.backup",
        "*~",
        "target/",
        ".mvn/wrapper/maven-wrapper.jar",
        "node_modules/"
    )
    
    $deletedCount = 0
    
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path $projectRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            try {
                if ($file.PSIsContainer) {
                    # Es un directorio
                    if ($file.Name -eq "target" -or $file.Name -eq "node_modules") {
                        Write-ColorOutput "🗑️  Eliminando: $($file.FullName)" "Gray"
                        Remove-Item -Path $file.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        $deletedCount++
                    }
                } else {
                    # Es un archivo
                    Write-ColorOutput "🗑️  Eliminando: $($file.FullName)" "Gray"
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    $deletedCount++
                }
            } catch {
                Write-ColorOutput "⚠️  No se pudo eliminar: $($file.FullName)" "Yellow"
            }
        }
    }
    
    if ($deletedCount -eq 0) {
        Write-ColorOutput "✅ No hay archivos temporales para limpiar" "Green"
    } else {
        Write-ColorOutput "✅ $deletedCount archivo(s)/carpeta(s) eliminados" "Green"
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🧹 Cleanup - Limpieza de recursos del proyecto" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Si se especifica -All, activar todas las banderas
if ($All) {
    $Docker = $true
    $Kubernetes = $true
    $TempFiles = $true
}

# Si no se especificó ninguna bandera, mostrar menú
if (-not $Docker -and -not $Kubernetes -and -not $TempFiles) {
    Write-ColorOutput "`n¿Qué deseas limpiar?" "Cyan"
    Write-ColorOutput "   1. Todo (Docker + Kubernetes + Archivos temporales)" "White"
    Write-ColorOutput "   2. Solo Docker" "White"
    Write-ColorOutput "   3. Solo Kubernetes" "White"
    Write-ColorOutput "   4. Solo archivos temporales" "White"
    Write-ColorOutput "   5. Cancelar" "White"
    
    $choice = Read-Host "`nSelecciona opción (1-5)"
    
    switch ($choice) {
        "1" { $Docker = $true; $Kubernetes = $true; $TempFiles = $true }
        "2" { $Docker = $true }
        "3" { $Kubernetes = $true }
        "4" { $TempFiles = $true }
        "5" { 
            Write-ColorOutput "❌ Operación cancelada" "Yellow"
            exit 0
        }
        default {
            Write-ColorOutput "❌ Opción inválida" "Red"
            exit 1
        }
    }
}

# Ejecutar limpiezas según las banderas
if ($Docker) {
    Clear-DockerResources
}

if ($Kubernetes) {
    Clear-KubernetesResources
}

if ($TempFiles) {
    Clear-TempFiles
}

# ============================================
# Resumen final
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "✅ LIMPIEZA COMPLETADA" "Green"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n💡 Recursos liberados:" "Cyan"
if ($Docker) {
    Write-ColorOutput "   ✅ Docker (contenedores, imágenes, volúmenes)" "White"
}
if ($Kubernetes) {
    Write-ColorOutput "   ✅ Kubernetes (namespace y recursos)" "White"
}
if ($TempFiles) {
    Write-ColorOutput "   ✅ Archivos temporales" "White"
}

Write-ColorOutput "`n📚 Para volver a desplegar:" "Cyan"
Write-ColorOutput "   Local:  ..\kubernetes\deploy-local.ps1" "White"
Write-ColorOutput "   Azure:  ..\kubernetes\deploy-aks.ps1" "White"

Write-Host ""