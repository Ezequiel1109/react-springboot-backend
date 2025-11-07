# Script para ejecutar tests con Testcontainers
# Este script maneja las rutas con espacios correctamente

param(
    [Parameter(Position=0)]
    [string]$TestClass = "*IT",
    [switch]$Verbose,
    [switch]$ShowLogs
)

$ErrorActionPreference = "Stop"

Write-Host "🐳 Ejecutando tests con Testcontainers..." -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Verificar si Docker está ejecutándose
Write-Host "🔍 Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker está ejecutándose (versión: $dockerVersion)" -ForegroundColor Green
    } else {
        throw "Docker no responde"
    }
} catch {
    Write-Host "❌ Error: Docker no está ejecutándose o no está instalado." -ForegroundColor Red
    Write-Host "   Por favor inicia Docker Desktop e intenta nuevamente." -ForegroundColor Yellow
    exit 1
}

# Configurar variables de entorno para Maven
$env:MAVEN_OPTS = "-Xmx1024m"
$env:TESTCONTAINERS_REUSE_ENABLE = "true"

# Comando Maven con manejo de rutas con espacios
$mvnCommand = "test"
$mvnArgs = @()

if ($TestClass -ne "*IT") {
    $mvnArgs += "-Dtest=$TestClass"
}

if ($Verbose) {
    $mvnArgs += "-X"
}

if ($ShowLogs) {
    $mvnArgs += "-Dorg.slf4j.simpleLogger.log.org.testcontainers=DEBUG"
}

# Añadir argumentos adicionales para Testcontainers
$mvnArgs += "-Dspring.profiles.active=test"
$mvnArgs += "-Djava.awt.headless=true"

Write-Host "🚀 Ejecutando comando:" -ForegroundColor Blue
$fullCommand = "mvnw.cmd $mvnCommand " + ($mvnArgs -join " ")
Write-Host "   $fullCommand" -ForegroundColor Gray
Write-Host ""

try {
    # Usar Start-Process para manejar rutas con espacios
    $processArgs = @{
        FilePath = "cmd.exe"
        ArgumentList = "/c", "mvnw.cmd", $mvnCommand
        WorkingDirectory = $PWD
        Wait = $true
        NoNewWindow = $true
    }
    
    # Añadir argumentos de Maven
    $processArgs.ArgumentList += $mvnArgs
    
    Write-Host "📦 Descargando y iniciando contenedores Docker..." -ForegroundColor Yellow
    Write-Host "   (Esto puede tomar varios minutos la primera vez)" -ForegroundColor Gray
    Write-Host ""
    
    $process = Start-Process @processArgs -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "✅ ¡Tests ejecutados exitosamente!" -ForegroundColor Green
        Write-Host "   Los contenedores Docker se han limpiado automáticamente." -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "❌ Los tests fallaron (código de salida: $($process.ExitCode))" -ForegroundColor Red
        exit $process.ExitCode
    }
} catch {
    Write-Host ""
    Write-Host "Error ejecutando los tests: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Informacion adicional:" -ForegroundColor Cyan
Write-Host "   • Los reportes de test estan en: target/surefire-reports/" -ForegroundColor Gray
Write-Host "   • Para ver logs detallados usa: -ShowLogs" -ForegroundColor Gray
Write-Host "   • Para tests especificos usa: .\run-testcontainers.ps1 'NombreDelTest'" -ForegroundColor Gray

Write-Host ""
Write-Host "Listo!" -ForegroundColor Green