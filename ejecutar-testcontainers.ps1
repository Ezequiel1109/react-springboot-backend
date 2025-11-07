# Script PowerShell para ejecutar Testcontainers desde cero
# Este script evita el problema de espacios en la ruta

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "    TESTCONTAINERS: EJECUCIÓN DESDE CERO" -ForegroundColor Cyan  
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Verificar Docker
Write-Host "🔍 Paso 1: Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker disponible: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Docker no está disponible" -ForegroundColor Red
    Write-Host "   Por favor inicia Docker Desktop" -ForegroundColor Yellow
    Read-Host "Presiona Enter para continuar..."
    exit 1
}

# Paso 2: Verificar contenedores activos
Write-Host ""
Write-Host "🐳 Paso 2: Verificando contenedores activos..." -ForegroundColor Yellow
$containers = docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
if ($containers.Count -gt 1) {
    Write-Host "Contenedores activos:" -ForegroundColor Cyan
    Write-Host $containers -ForegroundColor Gray
} else {
    Write-Host "✅ No hay contenedores activos (perfecto para tests limpios)" -ForegroundColor Green
}

# Paso 3: Mostrar opciones de ejecución
Write-Host ""
Write-Host "🚀 Paso 3: Opciones de ejecución disponibles:" -ForegroundColor Yellow
Write-Host "   1. Usar IDE (IntelliJ/VS Code/Eclipse) - MÁS RECOMENDADO" -ForegroundColor Cyan
Write-Host "   2. Usar Docker con Maven" -ForegroundColor Cyan
Write-Host "   3. Mover proyecto a ruta sin espacios" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona una opción (1, 2, 3) o presiona Enter para ver instrucciones"

switch ($opcion) {
    "1" {
        Write-Host ""
        Write-Host "📝 INSTRUCCIONES PARA IDE:" -ForegroundColor Green
        Write-Host "1. Abre IntelliJ IDEA, VS Code, o Eclipse" -ForegroundColor White
        Write-Host "2. Abre el proyecto desde esta carpeta" -ForegroundColor White
        Write-Host "3. Navega a: src/test/java/.../SimpleTestcontainersIT.java" -ForegroundColor White
        Write-Host "4. Haz clic derecho → 'Run Test' o 'Run SimpleTestcontainersIT'" -ForegroundColor White
        Write-Host "5. ¡Observa como Testcontainers descarga MySQL automáticamente!" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Esta es la forma MÁS FÁCIL y CONFIABLE" -ForegroundColor Yellow
    }
    "2" {
        Write-Host ""
        Write-Host "🐳 Ejecutando con Docker..." -ForegroundColor Green
        Write-Host "Esto puede tardar varios minutos la primera vez..." -ForegroundColor Yellow
        Write-Host ""
        
        # Usar Docker para ejecutar Maven
        try {
            $currentDir = Get-Location
            Write-Host "📁 Directorio actual: $currentDir" -ForegroundColor Gray
            Write-Host "⬇️ Descargando y ejecutando Maven en Docker..." -ForegroundColor Yellow
            
            docker run --rm -v "${currentDir}:/app" -w /app maven:3.9.5-eclipse-temurin-21 mvn clean test -Dtest=SimpleTestcontainersIT -DforkCount=1 -DreuseForks=false
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "🎉 ¡TESTS EXITOSOS!" -ForegroundColor Green
                Write-Host "Testcontainers funcionó correctamente" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "❌ Tests fallaron (código: $LASTEXITCODE)" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Error ejecutando Docker: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    "3" {
        Write-Host ""
        Write-Host "📂 INSTRUCCIONES PARA MOVER PROYECTO:" -ForegroundColor Green
        Write-Host "1. Crear directorio: mkdir C:\dev" -ForegroundColor White
        Write-Host "2. Copiar proyecto: xcopy /E /I `"$PWD`" `"C:\dev\react-springboot-backend`"" -ForegroundColor White
        Write-Host "3. Cambiar directorio: cd C:\dev\react-springboot-backend" -ForegroundColor White
        Write-Host "4. Ejecutar: .\mvnw.cmd test -Dtest=SimpleTestcontainersIT" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Esto soluciona el problema de espacios en 'Ivette Arias'" -ForegroundColor Yellow
    }
    default {
        Write-Host ""
        Write-Host "📋 RESUMEN DE QUÉ HACE TESTCONTAINERS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "🐳 AUTOMÁTICAMENTE:" -ForegroundColor Cyan
        Write-Host "   • Descarga imagen MySQL 8.0 (solo primera vez)" -ForegroundColor White
        Write-Host "   • Crea contenedor temporal con base de datos limpia" -ForegroundColor White
        Write-Host "   • Configura Spring Boot para conectarse automáticamente" -ForegroundColor White
        Write-Host "   • Ejecuta tests con MySQL REAL (no H2 en memoria)" -ForegroundColor White
        Write-Host "   • Limpia todo al terminar (sin contenedores huérfanos)" -ForegroundColor White
        Write-Host ""
        Write-Host "⏱️ TIEMPOS ESPERADOS:" -ForegroundColor Cyan
        Write-Host "   • Primera ejecución: 2-3 minutos (descarga MySQL)" -ForegroundColor White
        Write-Host "   • Siguientes ejecuciones: 30-60 segundos" -ForegroundColor White
        Write-Host ""
        Write-Host "✅ SI TODO FUNCIONA VERÁS:" -ForegroundColor Cyan
        Write-Host "   • Logs: '🐳 Iniciando contenedor MySQL'" -ForegroundColor White
        Write-Host "   • Logs: '✅ Usuario guardado con ID: 1'" -ForegroundColor White
        Write-Host "   • Resultado: 'Tests run: 4, Failures: 0'" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🎯 PRÓXIMO PASO RECOMENDADO:" -ForegroundColor Yellow
Write-Host "   Usa un IDE (opción 1) para la mejor experiencia" -ForegroundColor White
Write-Host ""
Read-Host "Presiona Enter para salir..."