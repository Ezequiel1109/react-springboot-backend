@echo off
REM Script batch para ejecutar tests de Testcontainers
REM Solución temporal para el problema de espacios en la ruta

echo ======================================
echo   TESTCONTAINERS - EJECUTANDO TESTS
echo ======================================

REM Verificar Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker no esta disponible
    echo Por favor inicia Docker Desktop
    pause
    exit /b 1
)

echo Docker OK - Ejecutando tests...
echo.

REM Usar Java y Maven directamente
set JAVA_HOME=
set MAVEN_OPTS=-Xmx1024m

REM Intentar con diferentes enfoques
if exist "mvnw.cmd" (
    echo Usando Maven wrapper...
    call mvnw.cmd test -Dtest=SimpleTestcontainersIT
) else (
    echo Maven wrapper no encontrado
    pause
    exit /b 1
)

if errorlevel 1 (
    echo.
    echo TESTS FALLARON
    echo Revisa los logs arriba para mas detalles
) else (
    echo.
    echo TESTS EXITOSOS!
    echo Testcontainers funciono correctamente
)

echo.
echo Presiona cualquier tecla para continuar...
pause >nul