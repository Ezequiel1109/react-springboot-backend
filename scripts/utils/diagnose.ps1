<#
.SYNOPSIS
    Diagnostica problemas del proyecto (Docker, Kubernetes, Java, Maven)

.DESCRIPTION
    Verifica:
    - Instalación de herramientas (Docker, kubectl, Java, Maven, Azure CLI)
    - Estado de contenedores y pods
    - Conectividad de red
    - Configuración de secrets y configmaps
    - Logs de errores

.EXAMPLE
    .\diagnose.ps1
#>

$ErrorActionPreference = "Continue"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Test-CommandExists($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Write-SectionHeader($title) {
    Write-Host "`n" -ForegroundColor Gray
    Write-ColorOutput "=" * 70 "Gray"
    Write-ColorOutput $title "Cyan"
    Write-ColorOutput "=" * 70 "Gray"
}

# ============================================
# Diagnóstico de herramientas
# ============================================
function Test-Tools {
    Write-SectionHeader "🔧 Verificando herramientas instaladas"
    
    $tools = @{
        "Docker" = "docker"
        "Kubernetes (kubectl)" = "kubectl"
        "Java" = "java"
        "Maven" = "mvn"
        "Azure CLI" = "az"
        "Git" = "git"
    }
    
    $allInstalled = $true
    
    foreach ($tool in $tools.GetEnumerator()) {
        Write-Host "`n📦 $($tool.Key): " -NoNewline
        
        if (Test-CommandExists $tool.Value) {
            Write-ColorOutput "✅ Instalado" "Green"
            
            # Obtener versión
            try {
                switch ($tool.Value) {
                    "docker" {
                        $version = docker --version
                        Write-ColorOutput "   Versión: $version" "Gray"
                    }
                    "kubectl" {
                        $version = kubectl version --client --short 2>$null
                        Write-ColorOutput "   $version" "Gray"
                    }
                    "java" {
                        $version = java -version 2>&1 | Select-Object -First 1
                        Write-ColorOutput "   $version" "Gray"
                    }
                    "mvn" {
                        $version = mvn --version | Select-Object -First 1
                        Write-ColorOutput "   $version" "Gray"
                    }
                    "az" {
                        $version = az version --output json | ConvertFrom-Json
                        Write-ColorOutput "   Versión: $($version.'azure-cli')" "Gray"
                    }
                    "git" {
                        $version = git --version
                        Write-ColorOutput "   $version" "Gray"
                    }
                }
            } catch {
                Write-ColorOutput "   (No se pudo obtener versión)" "Yellow"
            }
        } else {
            Write-ColorOutput "❌ NO instalado" "Red"
            $allInstalled = $false
            
            # Sugerencias de instalación
            switch ($tool.Value) {
                "docker" {
                    Write-ColorOutput "   💡 Instalar: https://www.docker.com/products/docker-desktop" "Yellow"
                }
                "kubectl" {
                    Write-ColorOutput "   💡 Instalar: winget install Kubernetes.kubectl" "Yellow"
                }
                "java" {
                    Write-ColorOutput "   💡 Instalar: winget install Microsoft.OpenJDK.21" "Yellow"
                }
                "mvn" {
                    Write-ColorOutput "   💡 Instalar: https://maven.apache.org/download.cgi" "Yellow"
                }
                "az" {
                    Write-ColorOutput "   💡 Instalar: winget install Microsoft.AzureCLI" "Yellow"
                }
                "git" {
                    Write-ColorOutput "   💡 Instalar: winget install Git.Git" "Yellow"
                }
            }
        }
    }
    
    return $allInstalled
}

# ============================================
# Diagnóstico de Docker
# ============================================
function Test-Docker {
    Write-SectionHeader "🐳 Diagnóstico de Docker"
    
    if (-not (Test-CommandExists "docker")) {
        Write-ColorOutput "❌ Docker no está instalado" "Red"
        return $false
    }
    
    # Verificar si Docker está corriendo
    Write-Host "`n🔍 Estado de Docker: " -NoNewline
    try {
        docker ps | Out-Null
        Write-ColorOutput "✅ Corriendo" "Green"
    } catch {
        Write-ColorOutput "❌ NO está corriendo" "Red"
        Write-ColorOutput "   💡 Inicia Docker Desktop" "Yellow"
        return $false
    }
    
    # Contenedores del proyecto
    Write-ColorOutput "`n📦 Contenedores del proyecto:" "Cyan"
    $containers = docker ps -a --filter "name=springboot" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    if ($containers -match "springboot") {
        Write-Host $containers
    } else {
        Write-ColorOutput "   ℹ️  No hay contenedores del proyecto" "Yellow"
    }
    
    # Imágenes del proyecto
    Write-ColorOutput "`n🖼️  Imágenes del proyecto:" "Cyan"
    $images = docker images "springboot-products" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
    
    if ($images -match "springboot-products") {
        Write-Host $images
    } else {
        Write-ColorOutput "   ℹ️  No hay imágenes del proyecto" "Yellow"
    }
    
    # Uso de recursos
    Write-ColorOutput "`n💻 Uso de recursos:" "Cyan"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    return $true
}

# ============================================
# Diagnóstico de Kubernetes
# ============================================
function Test-Kubernetes {
    Write-SectionHeader "☸️  Diagnóstico de Kubernetes"
    
    if (-not (Test-CommandExists "kubectl")) {
        Write-ColorOutput "❌ kubectl no está instalado" "Red"
        return $false
    }
    
    # Contexto actual
    Write-Host "`n🔍 Contexto actual: " -NoNewline
    try {
        $context = kubectl config current-context
        Write-ColorOutput $context "Green"
    } catch {
        Write-ColorOutput "❌ No hay contexto configurado" "Red"
        return $false
    }
    
    # Verificar cluster
    Write-Host "`n🌐 Conectividad con cluster: " -NoNewline
    try {
        kubectl cluster-info | Out-Null
        Write-ColorOutput "✅ Conectado" "Green"
    } catch {
        Write-ColorOutput "❌ No se puede conectar al cluster" "Red"
        return $false
    }
    
    $namespace = "springboot-products"
    
    # Verificar namespace
    Write-Host "`n📦 Namespace '$namespace': " -NoNewline
    kubectl get namespace $namespace 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Existe" "Green"
    } else {
        Write-ColorOutput "❌ No existe" "Yellow"
        Write-ColorOutput "   💡 Despliega primero: ..\kubernetes\deploy-local.ps1" "Yellow"
        return $false
    }
    
    # Pods
    Write-ColorOutput "`n🎯 Pods en '$namespace':" "Cyan"
    kubectl get pods -n $namespace -o wide
    
    # Services
    Write-ColorOutput "`n🌐 Services:" "Cyan"
    kubectl get svc -n $namespace
    
    # ConfigMaps y Secrets
    Write-ColorOutput "`n⚙️  ConfigMaps y Secrets:" "Cyan"
    kubectl get configmap,secret -n $namespace
    
    # PersistentVolumeClaims
    Write-ColorOutput "`n💾 PersistentVolumeClaims:" "Cyan"
    kubectl get pvc -n $namespace
    
    # Verificar pods con problemas
    Write-ColorOutput "`n🔍 Verificando pods con problemas..." "Cyan"
    $problemPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
    
    $hasProblems = $false
    foreach ($pod in $problemPods.items) {
        $podName = $pod.metadata.name
        $status = $pod.status.phase
        
        if ($status -ne "Running" -and $status -ne "Succeeded") {
            $hasProblems = $true
            Write-ColorOutput "`n⚠️  Pod con problemas: $podName" "Red"
            Write-ColorOutput "   Estado: $status" "Yellow"
            
            # Mostrar eventos
            Write-ColorOutput "   📋 Eventos recientes:" "Cyan"
            kubectl describe pod $podName -n $namespace | Select-String -Pattern "Events:" -Context 0,10
            
            # Mostrar logs
            Write-ColorOutput "`n   📝 Últimas líneas de logs:" "Cyan"
            kubectl logs $podName -n $namespace --tail=20 2>$null
        }
    }
    
    if (-not $hasProblems) {
        Write-ColorOutput "✅ Todos los pods están funcionando correctamente" "Green"
    }
    
    return $true
}

# ============================================
# Diagnóstico del proyecto
# ============================================
function Test-Project {
    Write-SectionHeader "📁 Diagnóstico del proyecto"
    
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    
    # Verificar estructura
    Write-ColorOutput "`n📂 Estructura de carpetas:" "Cyan"
    
    $requiredDirs = @{
        "src/main/java" = "Código fuente Java"
        "src/main/resources" = "Recursos (application.properties)"
        "scripts" = "Scripts de automatización"
        "K8s" = "Manifiestos de Kubernetes"
    }
    
    $allExist = $true
    foreach ($dir in $requiredDirs.GetEnumerator()) {
        $path = Join-Path $projectRoot $dir.Key
        Write-Host "   $($dir.Value): " -NoNewline
        if (Test-Path $path) {
            Write-ColorOutput "✅" "Green"
        } else {
            Write-ColorOutput "❌ Falta" "Red"
            $allExist = $false
        }
    }
    
    # Verificar archivos importantes
    Write-ColorOutput "`n📄 Archivos importantes:" "Cyan"
    
    $requiredFiles = @{
        "pom.xml" = "Maven config"
        "Dockerfile" = "Dockerfile producción"
        "docker-compose.yml" = "Docker Compose"
        "K8s/base/namespace.yaml" = "Namespace K8s"
        "K8s/base/configmap.yaml" = "ConfigMap"
        "K8s/base/secrets.yaml" = "Secrets"
    }
    
    foreach ($file in $requiredFiles.GetEnumerator()) {
        $path = Join-Path $projectRoot $file.Key
        Write-Host "   $($file.Value): " -NoNewline
        if (Test-Path $path) {
            Write-ColorOutput "✅" "Green"
        } else {
            Write-ColorOutput "❌ Falta" "Red"
            
            if ($file.Key -eq "K8s/base/secrets.yaml") {
                Write-ColorOutput "      💡 Genera con: ..\kubernetes\generate-secrets.ps1" "Yellow"
            }
        }
    }
    
    # Verificar application.properties
    Write-ColorOutput "`n⚙️  Configuración de Spring Boot:" "Cyan"
    $appProps = Join-Path $projectRoot "src\main\resources\application.properties"
    
    if (Test-Path $appProps) {
        $content = Get-Content $appProps -Raw
        
        # Verificar propiedades importantes
        $properties = @{
            "spring.datasource.url" = "URL de base de datos"
            "spring.jpa.hibernate.ddl-auto" = "Estrategia de DDL"
            "server.port" = "Puerto del servidor"
        }
        
        foreach ($prop in $properties.GetEnumerator()) {
            Write-Host "   $($prop.Value): " -NoNewline
            if ($content -match $prop.Key) {
                Write-ColorOutput "✅" "Green"
            } else {
                Write-ColorOutput "⚠️  No configurado" "Yellow"
            }
        }
    } else {
        Write-ColorOutput "   ❌ application.properties no encontrado" "Red"
    }
    
    return $allExist
}

# ============================================
# Diagnóstico de conectividad
# ============================================
function Test-Connectivity {
    Write-SectionHeader "🌐 Diagnóstico de conectividad"
    
    # Verificar conexión a internet
    Write-Host "`n🌍 Conexión a internet: " -NoNewline
    try {
        $response = Test-NetConnection -ComputerName "google.com" -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($response) {
            Write-ColorOutput "✅ Conectado" "Green"
        } else {
            Write-ColorOutput "❌ Sin conexión" "Red"
        }
    } catch {
        Write-ColorOutput "⚠️  No se pudo verificar" "Yellow"
    }
    
    # Verificar Docker Hub
    Write-Host "`n🐳 Docker Hub: " -NoNewline
    try {
        $response = Test-NetConnection -ComputerName "hub.docker.com" -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($response) {
            Write-ColorOutput "✅ Accesible" "Green"
        } else {
            Write-ColorOutput "⚠️  No accesible" "Yellow"
        }
    } catch {
        Write-ColorOutput "⚠️  No se pudo verificar" "Yellow"
    }
    
    # Verificar Azure (si Azure CLI está instalado)
    if (Test-CommandExists "az") {
        Write-Host "`n☁️  Azure: " -NoNewline
        $account = az account show 2>$null
        if ($account) {
            $accountInfo = $account | ConvertFrom-Json
            Write-ColorOutput "✅ Autenticado ($($accountInfo.user.name))" "Green"
        } else {
            Write-ColorOutput "⚠️  No autenticado" "Yellow"
            Write-ColorOutput "   💡 Ejecuta: az login" "Yellow"
        }
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🔍 DIAGNÓSTICO COMPLETO DEL PROYECTO" "Cyan"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"

# Ejecutar diagnósticos
$toolsOk = Test-Tools
$dockerOk = Test-Docker
$k8sOk = Test-Kubernetes
$projectOk = Test-Project
Test-Connectivity

# ============================================
# Resumen final
# ============================================
Write-SectionHeader "📊 RESUMEN DEL DIAGNÓSTICO"

$issues = @()

if (-not $toolsOk) {
    $issues += "⚠️  Faltan herramientas por instalar"
}
if (-not $dockerOk) {
    $issues += "⚠️  Problemas con Docker"
}
if (-not $k8sOk) {
    $issues += "⚠️  Problemas con Kubernetes"
}
if (-not $projectOk) {
    $issues += "⚠️  Faltan archivos del proyecto"
}

if ($issues.Count -eq 0) {
    Write-ColorOutput "`n✅ TODO ESTÁ FUNCIONANDO CORRECTAMENTE" "Green"
    Write-ColorOutput "`n💡 Puedes proceder con el despliegue:" "Cyan"
    Write-ColorOutput "   Local:  ..\kubernetes\deploy-local.ps1" "White"
    Write-ColorOutput "   Azure:  ..\kubernetes\deploy-aks.ps1" "White"
} else {
    Write-ColorOutput "`n⚠️  SE ENCONTRARON LOS SIGUIENTES PROBLEMAS:" "Yellow"
    foreach ($issue in $issues) {
        Write-ColorOutput "   $issue" "Red"
    }
    
    Write-ColorOutput "`n💡 Soluciones recomendadas:" "Cyan"
    Write-ColorOutput "   1. Instala las herramientas faltantes" "White"
    Write-ColorOutput "   2. Inicia Docker Desktop si no está corriendo" "White"
    Write-ColorOutput "   3. Genera secrets: ..\kubernetes\generate-secrets.ps1" "White"
    Write-ColorOutput "   4. Ejecuta cleanup si hay recursos corruptos: .\cleanup.ps1 -All" "White"
}

Write-Host "`n"