<#
.SYNOPSIS
    Configura el entorno de desarrollo completo del proyecto

.DESCRIPTION
    Script interactivo que guía al usuario para configurar:
    - Herramientas necesarias (Docker, kubectl, Java, Maven)
    - Docker Desktop con Kubernetes
    - Azure CLI y autenticación
    - Secrets de Kubernetes
    - Variables de entorno locales

.EXAMPLE
    .\setup-environment.ps1
#>

$ErrorActionPreference = "Continue"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Write-SectionHeader($title) {
    Write-Host "`n" -ForegroundColor Gray
    Write-ColorOutput "=" * 70 "Gray"
    Write-ColorOutput $title "Cyan"
    Write-ColorOutput "=" * 70 "Gray"
}

function Test-CommandExists($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Install-WithWinget($packageId, $packageName) {
    Write-ColorOutput "`n📦 Instalando $packageName..." "Yellow"
    
    if (-not (Test-CommandExists "winget")) {
        Write-ColorOutput "❌ winget no está disponible" "Red"
        Write-ColorOutput "   Instala manualmente desde la tienda de Microsoft" "Yellow"
        return $false
    }
    
    try {
        winget install $packageId --silent --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ $packageName instalado correctamente" "Green"
            return $true
        } else {
            Write-ColorOutput "⚠️  Instalación completada con advertencias" "Yellow"
            return $true
        }
    } catch {
        Write-ColorOutput "❌ Error al instalar $packageName" "Red"
        return $false
    }
}

# ============================================
# Verificar e instalar herramientas
# ============================================
function Initialize-Tools {
    Write-SectionHeader "🔧 Verificación e instalación de herramientas"
    
    $tools = @(
        @{
            Name = "Docker Desktop"
            Command = "docker"
            WingetId = "Docker.DockerDesktop"
            Manual = "https://www.docker.com/products/docker-desktop"
            Required = $true
        },
        @{
            Name = "Java (OpenJDK 21)"
            Command = "java"
            WingetId = "Microsoft.OpenJDK.21"
            Manual = "https://adoptium.net/"
            Required = $true
        },
        @{
            Name = "Maven"
            Command = "mvn"
            WingetId = "Apache.Maven"
            Manual = "https://maven.apache.org/download.cgi"
            Required = $true
        },
        @{
            Name = "kubectl"
            Command = "kubectl"
            WingetId = "Kubernetes.kubectl"
            Manual = "https://kubernetes.io/docs/tasks/tools/"
            Required = $false
        },
        @{
            Name = "Azure CLI"
            Command = "az"
            WingetId = "Microsoft.AzureCLI"
            Manual = "https://aka.ms/installazurecliwindows"
            Required = $false
        },
        @{
            Name = "Git"
            Command = "git"
            WingetId = "Git.Git"
            Manual = "https://git-scm.com/download/win"
            Required = $true
        }
    )
    
    $missingTools = @()
    
    foreach ($tool in $tools) {
        Write-Host "`n📦 Verificando $($tool.Name)... " -NoNewline
        
        if (Test-CommandExists $tool.Command) {
            Write-ColorOutput "✅ Ya instalado" "Green"
        } else {
            Write-ColorOutput "❌ NO instalado" "Red"
            $missingTools += $tool
        }
    }
    
    if ($missingTools.Count -eq 0) {
        Write-ColorOutput "`n✅ Todas las herramientas están instaladas" "Green"
        return $true
    }
    
    # Ofrecer instalar herramientas faltantes
    Write-ColorOutput "`n⚠️  Faltan $($missingTools.Count) herramienta(s)" "Yellow"
    
    foreach ($tool in $missingTools) {
        Write-ColorOutput "`n🔧 $($tool.Name)" "Cyan"
        
        if ($tool.Required) {
            Write-ColorOutput "   ⚠️  REQUERIDA para el proyecto" "Red"
        }
        
        $response = Read-Host "¿Deseas instalar $($tool.Name)? (y/n)"
        
        if ($response -eq "y" -or $response -eq "Y") {
            $installed = Install-WithWinget -packageId $tool.WingetId -packageName $tool.Name
            
            if (-not $installed) {
                Write-ColorOutput "`n💡 Instalación manual:" "Yellow"
                Write-ColorOutput "   $($tool.Manual)" "White"
            }
        } else {
            Write-ColorOutput "   ⏭️  Saltado" "Yellow"
            
            if ($tool.Required) {
                Write-ColorOutput "   ⚠️  Necesitarás instalarlo manualmente: $($tool.Manual)" "Red"
            }
        }
    }
    
    Write-ColorOutput "`n💡 Puede que necesites reiniciar la terminal para que los cambios surtan efecto" "Yellow"
    
    return $false
}

# ============================================
# Configurar Docker Desktop
# ============================================
function Initialize-Docker {
    Write-SectionHeader "🐳 Configuración de Docker Desktop"
    
    if (-not (Test-CommandExists "docker")) {
        Write-ColorOutput "`n⚠️  Docker no está instalado. Instálalo primero." "Yellow"
        return $false
    }
    
    # Verificar si Docker está corriendo
    Write-Host "`n🔍 Verificando Docker... " -NoNewline
    try {
        docker ps | Out-Null
        Write-ColorOutput "✅ Docker está corriendo" "Green"
    } catch {
        Write-ColorOutput "❌ Docker NO está corriendo" "Red"
        Write-ColorOutput "`n💡 Pasos para iniciar Docker Desktop:" "Yellow"
        Write-ColorOutput "   1. Abre Docker Desktop desde el menú de inicio" "White"
        Write-ColorOutput "   2. Espera a que el icono en la bandeja del sistema esté verde" "White"
        Write-ColorOutput "   3. Vuelve a ejecutar este script" "White"
        return $false
    }
    
    # Verificar Kubernetes en Docker Desktop
    Write-Host "`n☸️  Verificando Kubernetes en Docker Desktop... " -NoNewline
    
    $contexts = kubectl config get-contexts 2>$null
    if ($contexts -match "docker-desktop") {
        Write-ColorOutput "✅ Kubernetes habilitado" "Green"
    } else {
        Write-ColorOutput "❌ Kubernetes NO habilitado" "Red"
        Write-ColorOutput "`n💡 Pasos para habilitar Kubernetes:" "Yellow"
        Write-ColorOutput "   1. Abre Docker Desktop" "White"
        Write-ColorOutput "   2. Ve a Settings → Kubernetes" "White"
        Write-ColorOutput "   3. Marca 'Enable Kubernetes'" "White"
        Write-ColorOutput "   4. Click en 'Apply & Restart'" "White"
        Write-ColorOutput "   5. Espera 2-3 minutos a que se instale" "White"
        
        $response = Read-Host "`n¿Deseas abrir Docker Desktop ahora? (y/n)"
        if ($response -eq "y" -or $response -eq "Y") {
            Start-Process "docker"
        }
        
        return $false
    }
    
    return $true
}

# ============================================
# Configurar Azure CLI
# ============================================
function Initialize-Azure {
    Write-SectionHeader "☁️  Configuración de Azure CLI"
    
    if (-not (Test-CommandExists "az")) {
        Write-ColorOutput "`n⚠️  Azure CLI no está instalado" "Yellow"
        Write-ColorOutput "   (Opcional - solo necesario para despliegues en Azure)" "Gray"
        return $true
    }
    
    Write-Host "`n🔍 Verificando autenticación... " -NoNewline
    $account = az account show 2>$null
    
    if ($account) {
        $accountInfo = $account | ConvertFrom-Json
        Write-ColorOutput "✅ Ya autenticado" "Green"
        Write-ColorOutput "   Usuario: $($accountInfo.user.name)" "Gray"
        Write-ColorOutput "   Suscripción: $($accountInfo.name)" "Gray"
        return $true
    }
    
    Write-ColorOutput "❌ No autenticado" "Red"
    
    $response = Read-Host "`n¿Deseas autenticarte en Azure ahora? (y/n)"
    
    if ($response -eq "y" -or $response -eq "Y") {
        Write-ColorOutput "`n🔐 Iniciando proceso de autenticación..." "Cyan"
        az login
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Autenticado correctamente" "Green"
            return $true
        } else {
            Write-ColorOutput "❌ Error al autenticar" "Red"
            return $false
        }
    }
    
    Write-ColorOutput "⏭️  Saltado" "Yellow"
    return $true
}

# ============================================
# Generar Secrets de Kubernetes
# ============================================
function Initialize-Secrets {
    Write-SectionHeader "🔐 Configuración de Secrets para Kubernetes"
    
    $secretsPath = "..\..\K8s\base\secrets.yaml"
    
    Write-Host "`n🔍 Verificando secrets.yaml... " -NoNewline
    
    if (Test-Path $secretsPath) {
        Write-ColorOutput "✅ Ya existe" "Green"
        
        $response = Read-Host "`n¿Deseas regenerar los secrets? (y/n)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-ColorOutput "⏭️  Manteniendo secrets existentes" "Yellow"
            return $true
        }
    } else {
        Write-ColorOutput "❌ No existe" "Red"
    }
    
    Write-ColorOutput "`n🔐 Generando secrets..." "Cyan"
    
    $generateScript = "..\kubernetes\generate-secrets.ps1"
    
    if (Test-Path $generateScript) {
        & $generateScript
        return $true
    } else {
        Write-ColorOutput "❌ Script generate-secrets.ps1 no encontrado" "Red"
        return $false
    }
}

# ============================================
# Configurar variables de entorno locales
# ============================================
function Initialize-LocalEnvironment {
    Write-SectionHeader "⚙️  Configuración de variables de entorno locales"
    
    $envFile = "..\..\..\.env"
    
    Write-ColorOutput "`n📝 Creando archivo .env para desarrollo local..." "Cyan"
    
    $envContent = @"
# ============================================
# Variables de entorno para desarrollo local
# ============================================
# Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Base de datos
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/db_backend_crud?useSSL=false
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=root

# Puerto del servidor
SERVER_PORT=8080

# Perfil activo
SPRING_PROFILES_ACTIVE=dev

# JPA/Hibernate
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=true

# JWT (usar un secret seguro en producción)
JWT_SECRET=your-secret-key-change-in-production
"@

    if (Test-Path $envFile) {
        Write-ColorOutput "⚠️  .env ya existe" "Yellow"
        
        $response = Read-Host "¿Deseas sobrescribirlo? (y/n)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-ColorOutput "⏭️  Manteniendo .env existente" "Yellow"
            return $true
        }
    }
    
    $envContent | Out-File -FilePath $envFile -Encoding UTF8
    Write-ColorOutput "✅ Archivo .env creado" "Green"
    
    # Verificar .gitignore
    $gitignorePath = "..\..\..\..\.gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath -Raw
        if (-not $gitignoreContent.Contains(".env")) {
            Write-ColorOutput "`n📝 Agregando .env a .gitignore..." "Yellow"
            Add-Content -Path $gitignorePath -Value "`n# Environment variables`n.env"
            Write-ColorOutput "✅ Agregado a .gitignore" "Green"
        }
    }
    
    return $true
}

# ============================================
# Verificar estructura del proyecto
# ============================================
function Test-ProjectStructure {
    Write-SectionHeader "📁 Verificación de estructura del proyecto"
    
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    
    $requiredItems = @(
        @{ Path = "src\main\java"; Type = "Folder"; Name = "Código fuente Java" },
        @{ Path = "src\main\resources"; Type = "Folder"; Name = "Recursos" },
        @{ Path = "pom.xml"; Type = "File"; Name = "Maven config" },
        @{ Path = "Dockerfile"; Type = "File"; Name = "Dockerfile" },
        @{ Path = "K8s"; Type = "Folder"; Name = "Manifiestos K8s" },
        @{ Path = "scripts"; Type = "Folder"; Name = "Scripts" }
    )
    
    $allExist = $true
    
    foreach ($item in $requiredItems) {
        $fullPath = Join-Path $projectRoot $item.Path
        Write-Host "`n   $($item.Name): " -NoNewline
        
        if (Test-Path $fullPath) {
            Write-ColorOutput "✅" "Green"
        } else {
            Write-ColorOutput "❌ Falta" "Red"
            $allExist = $false
        }
    }
    
    if ($allExist) {
        Write-ColorOutput "`n✅ Estructura del proyecto correcta" "Green"
    } else {
        Write-ColorOutput "`n⚠️  Faltan algunos archivos/carpetas" "Yellow"
    }
    
    return $allExist
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🚀 CONFIGURACIÓN DE ENTORNO DE DESARROLLO" "Cyan"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "Este script te ayudará a configurar todo lo necesario para desarrollar" "White"
Write-ColorOutput "y desplegar el proyecto Spring Boot con Kubernetes." "White"

Write-Host "`nPresiona Enter para continuar..." -ForegroundColor Yellow
Read-Host

# Ejecutar pasos de configuración
$results = @{
    "Tools" = Initialize-Tools
    "Docker" = Initialize-Docker
    "Azure" = Initialize-Azure
    "Secrets" = Initialize-Secrets
    "Environment" = Initialize-LocalEnvironment
    "Structure" = Test-ProjectStructure
}

# ============================================
# Resumen final
# ============================================
Write-SectionHeader "📊 RESUMEN DE CONFIGURACIÓN"

$allSuccess = $true

foreach ($step in $results.GetEnumerator()) {
    Write-Host "`n   $($step.Key): " -NoNewline
    if ($step.Value) {
        Write-ColorOutput "✅ Completado" "Green"
    } else {
        Write-ColorOutput "⚠️  Requiere atención" "Yellow"
        $allSuccess = $false
    }
}

# ============================================
# Próximos pasos
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"

if ($allSuccess) {
    Write-ColorOutput "✅ CONFIGURACIÓN COMPLETADA EXITOSAMENTE" "Green"
    Write-ColorOutput "=" * 70 "Gray"
    
    Write-ColorOutput "`n🎉 ¡Listo para empezar a desarrollar!" "Green"
    
    Write-ColorOutput "`n💡 Próximos pasos recomendados:" "Cyan"
    Write-ColorOutput "`n1️⃣  Ejecutar aplicación localmente:" "Yellow"
    Write-ColorOutput "   cd ..\..\docker" "White"
    Write-ColorOutput "   .\run-local.ps1" "White"
    
    Write-ColorOutput "`n2️⃣  O desplegar en Kubernetes local:" "Yellow"
    Write-ColorOutput "   cd ..\..\kubernetes" "White"
    Write-ColorOutput "   .\deploy-local.ps1" "White"
    
    Write-ColorOutput "`n3️⃣  Ver documentación completa:" "Yellow"
    Write-ColorOutput "   README.md principal" "White"
    Write-ColorOutput "   scripts\docker\README.md" "White"
    Write-ColorOutput "   scripts\kubernetes\README.md" "White"
    
} else {
    Write-ColorOutput "⚠️  CONFIGURACIÓN COMPLETADA CON ADVERTENCIAS" "Yellow"
    Write-ColorOutput "=" * 70 "Gray"
    
    Write-ColorOutput "`n💡 Revisa los pasos marcados con ⚠️  y completa la configuración" "Yellow"
    
    Write-ColorOutput "`n📚 Recursos útiles:" "Cyan"
    Write-ColorOutput "   - Ejecuta diagnóstico: .\diagnose.ps1" "White"
    Write-ColorOutput "   - Ver scripts disponibles: .\list-scripts.ps1" "White"
    Write-ColorOutput "   - Documentación: ..\..\README.md" "White"
}

Write-Host "`n"