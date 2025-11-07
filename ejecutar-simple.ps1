# Script simple para ejecutar Testcontainers desde cero

Write-Host "=============================================="
Write-Host "    TESTCONTAINERS: EJECUCION DESDE CERO"
Write-Host "=============================================="
Write-Host ""

# Verificar Docker
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker disponible: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker no esta disponible" -ForegroundColor Red
    Write-Host "Por favor inicia Docker Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "OPCIONES DE EJECUCION:" -ForegroundColor Yellow
Write-Host "1. IDE (IntelliJ/VS Code) - MAS RECOMENDADO" -ForegroundColor Cyan
Write-Host "2. Docker con Maven" -ForegroundColor Cyan  
Write-Host "3. Ver instrucciones detalladas" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona opcion (1, 2, 3)"

if ($opcion -eq "1") {
    Write-Host ""
    Write-Host "INSTRUCCIONES PARA IDE:" -ForegroundColor Green
    Write-Host "1. Abrir IntelliJ IDEA, VS Code, o Eclipse"
    Write-Host "2. Abrir proyecto desde esta carpeta"
    Write-Host "3. Ir a: src/test/java/.../SimpleTestcontainersIT.java"
    Write-Host "4. Clic derecho -> Run Test"
    Write-Host "5. Observar como Testcontainers descarga MySQL!"
    Write-Host ""
    Write-Host "Esta es la forma MAS FACIL y CONFIABLE" -ForegroundColor Yellow
}
elseif ($opcion -eq "2") {
    Write-Host ""
    Write-Host "Ejecutando con Docker..." -ForegroundColor Green
    Write-Host "Esto puede tardar varios minutos la primera vez..." -ForegroundColor Yellow
    
    $currentDir = Get-Location
    docker run --rm -v "${currentDir}:/app" -w /app maven:3.9.5-eclipse-temurin-21 mvn test -Dtest=SimpleTestcontainersIT
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "TESTS EXITOSOS!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Tests fallaron" -ForegroundColor Red
    }
}
else {
    Write-Host ""
    Write-Host "QUE HACE TESTCONTAINERS:" -ForegroundColor Green
    Write-Host "• Descarga imagen MySQL 8.0 automaticamente"
    Write-Host "• Crea contenedor temporal con base de datos limpia"
    Write-Host "• Configura Spring Boot para conectarse"
    Write-Host "• Ejecuta tests con MySQL REAL"
    Write-Host "• Limpia todo al terminar"
    Write-Host ""
    Write-Host "TIEMPOS ESPERADOS:"
    Write-Host "• Primera ejecucion: 2-3 minutos"
    Write-Host "• Siguientes: 30-60 segundos"
    Write-Host ""
    Write-Host "RECOMENDACION: Usar IDE (opcion 1)"
}

Write-Host ""
Read-Host "Presiona Enter para continuar"