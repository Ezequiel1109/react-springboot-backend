<#
.SYNOPSIS
    Lista todos los scripts disponibles en el proyecto

.DESCRIPTION
    Muestra de forma organizada todos los scripts PowerShell disponibles
    con su descripción y uso básico.

.EXAMPLE
    .\list-scripts.ps1
#>

$ErrorActionPreference = "Continue"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Get-ScriptDescription($scriptPath) {
    try {
        $content = Get-Content $scriptPath -TotalCount 20 -ErrorAction SilentlyContinue
        $synopsis = $content | Where-Object { $_ -match "^\s*\.SYNOPSIS" }
        
        if ($synopsis) {
            $index = $content.IndexOf($synopsis)
            $description = $content[$index + 1]
            return ($description -replace "^\s*", "").Trim()
        }
        
        # Si no tiene SYNOPSIS, buscar comentario de una línea
        $singleLineComment = $content | Where-Object { $_ -match "^# " -and $_ -notmatch "filepath:" } | Select-Object -First 1
        if ($singleLineComment) {
            return ($singleLineComment -replace "^# ", "").Trim()
        }
        
        return "Sin descripción"
    } catch {
        return "Sin descripción"
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "`n📜 SCRIPTS DISPONIBLES DEL PROYECTO" "Cyan"
Write-ColorOutput "=" * 80 "Gray"

$scriptsRoot = Split-Path -Parent $PSScriptRoot

$categories = [ordered]@{
    "docker" = @{
        "Icon" = "🐳"
        "Name" = "Scripts de Docker"
        "Description" = "Gestión de contenedores e imágenes Docker"
    }
    "kubernetes" = @{
        "Icon" = "☸️"
        "Name" = "Scripts de Kubernetes"
        "Description" = "Despliegue en Kubernetes (local y Azure)"
    }
    "utils" = @{
        "Icon" = "🛠️"
        "Name" = "Scripts de Utilidad"
        "Description" = "Herramientas de soporte y diagnóstico"
    }
}

foreach ($folder in $categories.Keys) {
    $category = $categories[$folder]
    $folderPath = Join-Path $scriptsRoot $folder
    
    if (Test-Path $folderPath) {
        Write-ColorOutput "`n$($category.Icon) $($category.Name)" "Green"
        Write-ColorOutput ("─" * 80) "Gray"
        Write-ColorOutput $category.Description "Gray"
        Write-Host ""
        
        $scripts = Get-ChildItem -Path $folderPath -Filter "*.ps1" | Sort-Object Name
        
        if ($scripts.Count -eq 0) {
            Write-ColorOutput "   (No hay scripts en esta categoría)" "Yellow"
            continue
        }
        
        foreach ($script in $scripts) {
            $description = Get-ScriptDescription $script.FullName
            
            # Nombre del script
            Write-Host "   📄 " -NoNewline -ForegroundColor Yellow
            Write-Host $script.Name -NoNewline -ForegroundColor White
            
            # Descripción
            if ($description -ne "Sin descripción") {
                Write-Host " - " -NoNewline -ForegroundColor Gray
                Write-Host $description -ForegroundColor Gray
            } else {
                Write-Host ""
            }
            
            # Ruta relativa
            $relativePath = ".\$folder\$($script.Name)"
            Write-Host "      Uso: " -NoNewline -ForegroundColor DarkGray
            Write-Host $relativePath -ForegroundColor DarkGray
            Write-Host ""
        }
    }
}

# ============================================
# Scripts destacados
# ============================================
Write-ColorOutput "`n⭐ SCRIPTS MÁS UTILIZADOS" "Cyan"
Write-ColorOutput ("─" * 80) "Gray"

$highlightedScripts = @(
    @{
        Path = ".\docker\docker-manager.ps1"
        Description = "🐳 Gestión completa de Docker (build, run, push, etc.)"
        Example = ".\docker\docker-manager.ps1 -Environment prod -Action build-run"
    },
    @{
        Path = ".\docker\run-local.ps1"
        Description = "🚀 Inicio rápido de la aplicación localmente"
        Example = ".\docker\run-local.ps1"
    },
    @{
        Path = ".\kubernetes\deploy-local.ps1"
        Description = "☸️  Desplegar en Docker Desktop Kubernetes"
        Example = ".\kubernetes\deploy-local.ps1"
    },
    @{
        Path = ".\kubernetes\deploy-aks.ps1"
        Description = "☁️  Desplegar en Azure Kubernetes Service"
        Example = ".\kubernetes\deploy-aks.ps1"
    },
    @{
        Path = ".\kubernetes\generate-secrets.ps1"
        Description = "🔐 Generar secrets para Kubernetes"
        Example = ".\kubernetes\generate-secrets.ps1"
    },
    @{
        Path = ".\utils\diagnose.ps1"
        Description = "🔍 Diagnosticar problemas del proyecto"
        Example = ".\utils\diagnose.ps1"
    },
    @{
        Path = ".\utils\cleanup.ps1"
        Description = "🧹 Limpiar recursos de Docker y Kubernetes"
        Example = ".\utils\cleanup.ps1 -All"
    }
)

foreach ($script in $highlightedScripts) {
    Write-Host "`n   " -NoNewline
    Write-ColorOutput $script.Description "Yellow"
    Write-Host "      📝 " -NoNewline -ForegroundColor Gray
    Write-Host $script.Example -ForegroundColor White
}

# ============================================
# Guías rápidas
# ============================================
Write-ColorOutput "`n`n🎯 GUÍAS RÁPIDAS" "Cyan"
Write-ColorOutput ("─" * 80) "Gray"

Write-ColorOutput "`n💻 Desarrollo Local:" "Green"
Write-Host "   1. Ejecuta: " -NoNewline -ForegroundColor White
Write-Host ".\docker\run-local.ps1" -ForegroundColor Yellow
Write-Host "   2. Abre:   " -NoNewline -ForegroundColor White
Write-Host "http://localhost:8080" -ForegroundColor Cyan

Write-ColorOutput "`n☸️  Despliegue en Kubernetes (Docker Desktop):" "Green"
Write-Host "   1. Genera secrets: " -NoNewline -ForegroundColor White
Write-Host ".\kubernetes\generate-secrets.ps1" -ForegroundColor Yellow
Write-Host "   2. Despliega:      " -NoNewline -ForegroundColor White
Write-Host ".\kubernetes\deploy-local.ps1" -ForegroundColor Yellow
Write-Host "   3. Port-forward:   " -NoNewline -ForegroundColor White
Write-Host "kubectl port-forward svc/backend-service 8080:80 -n springboot-products" -ForegroundColor Yellow

Write-ColorOutput "`n☁️  Despliegue en Azure AKS:" "Green"
Write-Host "   1. Build y push: " -NoNewline -ForegroundColor White
Write-Host ".\kubernetes\build-and-push.ps1 -ACRName 'miacr'" -ForegroundColor Yellow
Write-Host "   2. Despliega:    " -NoNewline -ForegroundColor White
Write-Host ".\kubernetes\deploy-aks.ps1" -ForegroundColor Yellow

Write-ColorOutput "`n🧹 Limpiar todo:" "Green"
Write-Host "   " -NoNewline
Write-Host ".\utils\cleanup.ps1 -All" -ForegroundColor Yellow

Write-ColorOutput "`n🔍 Diagnosticar problemas:" "Green"
Write-Host "   " -NoNewline
Write-Host ".\utils\diagnose.ps1" -ForegroundColor Yellow

# ============================================
# Ayuda adicional
# ============================================
Write-ColorOutput "`n`n📚 AYUDA ADICIONAL" "Cyan"
Write-ColorOutput ("─" * 80) "Gray"

Write-ColorOutput "`nVer ayuda detallada de un script:" "Yellow"
Write-Host "   Get-Help .\<ruta-script>.ps1 -Full" -ForegroundColor White

Write-ColorOutput "`nVer ejemplos de uso:" "Yellow"
Write-Host "   Get-Help .\<ruta-script>.ps1 -Examples" -ForegroundColor White

Write-ColorOutput "`nLeer README de cada categoría:" "Yellow"
Write-Host "   .\docker\README.md" -ForegroundColor White
Write-Host "   .\kubernetes\README.md" -ForegroundColor White
Write-Host "   .\utils\README.md" -ForegroundColor White

Write-ColorOutput "`n📖 Documentación completa del proyecto:" "Yellow"
Write-Host "   ..\..\README.md" -ForegroundColor White
Write-Host "   ..\..\K8s\README.md" -ForegroundColor White

Write-Host "`n"