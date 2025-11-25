# Guía de ejecución de Testcontainers
# =====================================

# OPCIÓN 1: Usar IDE (Recomendado para desarrollo)
# --------------------------------------------------
# 1. Abre IntelliJ IDEA o tu IDE favorito
# 2. Asegúrate de que Docker Desktop está ejecutándose
# 3. Haz clic derecho en la clase de test
# 4. Selecciona "Run ProductControllerMySqlIT"
# 5. ¡Listo! Testcontainers manejará todo automáticamente

# OPCIÓN 2: Instalar Maven globalmente
# -------------------------------------
# 1. Descargar Maven desde: https://maven.apache.org/download.cgi
# 2. Extraer y configurar PATH
# 3. Ejecutar: mvn test -Dtest="*IT"

# OPCIÓN 3: Usar Docker para Maven (sin instalar Maven)
# ------------------------------------------------------
# Asegúrate de que Docker Desktop está ejecutándose primero
# Luego ejecuta:

Write-Host "Preparando ejecución con Docker..." -ForegroundColor Yellow

# Comando para Windows con PowerShell
$dockerCommand = @"
docker run --rm \
  -v "${PWD}:/app" \
  -v "//var/run/docker.sock:/var/run/docker.sock" \
  -w /app \
  maven:3.9.5-eclipse-temurin-21 \
  mvn test -Dtest="*IT"
"@

Write-Host "Comando Docker:" -ForegroundColor Green
Write-Host $dockerCommand -ForegroundColor Gray

# OPCIÓN 4: Solucionar el problema del Maven Wrapper
# ---------------------------------------------------
# El problema es el espacio en "Ivette Arias"
# Solución: mover el proyecto a una ruta sin espacios
# Ejemplo: C:\dev\react-springboot-backend

Write-Host ""
Write-Host "PROBLEMA ACTUAL:" -ForegroundColor Red
Write-Host "La ruta contiene espacios: 'Ivette Arias'" -ForegroundColor Yellow
Write-Host "Esto causa problemas con mvnw.cmd" -ForegroundColor Yellow

Write-Host ""
Write-Host "SOLUCIONES:" -ForegroundColor Green
Write-Host "1. Mover proyecto a: C:\dev\react-springboot-backend" -ForegroundColor Cyan
Write-Host "2. Usar IDE (IntelliJ/Eclipse)" -ForegroundColor Cyan
Write-Host "3. Instalar Maven globalmente" -ForegroundColor Cyan
Write-Host "4. Usar Docker con Maven" -ForegroundColor Cyan