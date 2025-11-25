<#
.SYNOPSIS
    Prueba los endpoints de la API REST del backend

.DESCRIPTION
    Script para probar los endpoints principales del backend:
    - Health check
    - Listar productos
    - Crear producto
    - Obtener producto por ID
    - Actualizar producto
    - Eliminar producto

.PARAMETER BaseUrl
    URL base de la API (por defecto: http://localhost:8080)

.PARAMETER Verbose
    Muestra información detallada de las peticiones

.EXAMPLE
    .\test-api-requests.ps1
    .\test-api-requests.ps1 -BaseUrl "http://localhost:8080"
    .\test-api-requests.ps1 -Verbose
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "http://localhost:8080",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

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

function Test-ApiEndpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description,
        [object]$Body = $null
    )
    
    Write-Host "`n🔍 $Description" -ForegroundColor Yellow
    Write-Host "   $Method $Endpoint" -ForegroundColor Gray
    
    $url = "$BaseUrl$Endpoint"
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        
        $params = @{
            Uri = $url
            Method = $Method
            Headers = $headers
            TimeoutSec = 10
        }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $params.Body = $jsonBody
            
            if ($Verbose) {
                Write-ColorOutput "`n   📤 Request Body:" "Gray"
                Write-Host "   $jsonBody" -ForegroundColor DarkGray
            }
        }
        
        $startTime = Get-Date
        $response = Invoke-RestMethod @params
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-ColorOutput "   ✅ Success (${duration}ms)" "Green"
        
        if ($Verbose) {
            Write-ColorOutput "`n   📥 Response:" "Gray"
            $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor DarkGray
        } else {
            if ($response) {
                Write-ColorOutput "   📄 Response preview:" "Gray"
                $preview = ($response | ConvertTo-Json -Depth 2 -Compress).Substring(0, [Math]::Min(100, ($response | ConvertTo-Json -Depth 2 -Compress).Length))
                Write-Host "   $preview..." -ForegroundColor DarkGray
            }
        }
        
        return @{
            Success = $true
            Data = $response
            Duration = $duration
        }
        
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-ColorOutput "   ❌ Error: $statusCode $statusDescription" "Red"
        
        if ($Verbose) {
            Write-ColorOutput "   📋 Details:" "Gray"
            Write-Host "   $($_.Exception.Message)" -ForegroundColor DarkGray
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = $statusCode
        }
    }
}

function Test-ServerAvailability {
    Write-Host "`n🔍 Verificando disponibilidad del servidor..." -ForegroundColor Cyan
    Write-Host "   URL: $BaseUrl" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health" -Method GET -TimeoutSec 5 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-ColorOutput "   ✅ Servidor disponible" "Green"
            return $true
        } else {
            Write-ColorOutput "   ⚠️  Servidor respondió con código: $($response.StatusCode)" "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "   ❌ Servidor NO disponible" "Red"
        Write-ColorOutput "   💡 Asegúrate de que la aplicación esté corriendo:" "Yellow"
        Write-ColorOutput "      - Local: .\docker\run-local.ps1" "White"
        Write-ColorOutput "      - K8s:   kubectl port-forward svc/backend-service 8080:80 -n springboot-products" "White"
        return $false
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "🧪 TEST DE ENDPOINTS DE LA API" "Cyan"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "Base URL: $BaseUrl" "Gray"

if ($Verbose) {
    Write-ColorOutput "Modo: Verbose (detallado)" "Gray"
}

# Verificar disponibilidad
if (-not (Test-ServerAvailability)) {
    exit 1
}

# ============================================
# 1. Health Check
# ============================================
Write-SectionHeader "1️⃣  Health Check"

$healthResult = Test-ApiEndpoint `
    -Method "GET" `
    -Endpoint "/actuator/health" `
    -Description "Verificar estado de la aplicación"

# ============================================
# 2. Listar todos los productos
# ============================================
Write-SectionHeader "2️⃣  Listar Productos"

$listResult = Test-ApiEndpoint `
    -Method "GET" `
    -Endpoint "/api/v1/products" `
    -Description "Obtener lista de todos los productos"

# ============================================
# 3. Crear nuevo producto
# ============================================
Write-SectionHeader "3️⃣  Crear Producto"

$newProduct = @{
    name = "Producto de Prueba $(Get-Random -Minimum 1000 -Maximum 9999)"
    description = "Descripción del producto de prueba"
    price = 99.99
    stock = 50
    category = "Test"
}

$createResult = Test-ApiEndpoint `
    -Method "POST" `
    -Endpoint "/api/v1/products" `
    -Description "Crear nuevo producto" `
    -Body $newProduct

$createdProductId = $null
if ($createResult.Success -and $createResult.Data.id) {
    $createdProductId = $createResult.Data.id
    Write-ColorOutput "`n   📝 Producto creado con ID: $createdProductId" "Green"
}

# ============================================
# 4. Obtener producto por ID
# ============================================
if ($createdProductId) {
    Write-SectionHeader "4️⃣  Obtener Producto por ID"
    
    $getResult = Test-ApiEndpoint `
        -Method "GET" `
        -Endpoint "/api/v1/products/$createdProductId" `
        -Description "Obtener producto con ID: $createdProductId"
}

# ============================================
# 5. Actualizar producto
# ============================================
if ($createdProductId) {
    Write-SectionHeader "5️⃣  Actualizar Producto"
    
    $updatedProduct = @{
        name = "Producto Actualizado"
        description = "Descripción actualizada"
        price = 149.99
        stock = 75
        category = "Test Updated"
    }
    
    $updateResult = Test-ApiEndpoint `
        -Method "PUT" `
        -Endpoint "/api/v1/products/$createdProductId" `
        -Description "Actualizar producto con ID: $createdProductId" `
        -Body $updatedProduct
}

# ============================================
# 6. Buscar productos por nombre
# ============================================
Write-SectionHeader "6️⃣  Buscar Productos"

$searchResult = Test-ApiEndpoint `
    -Method "GET" `
    -Endpoint "/api/v1/products/search?name=Producto" `
    -Description "Buscar productos que contengan 'Producto'"

# ============================================
# 7. Eliminar producto
# ============================================
if ($createdProductId) {
    Write-SectionHeader "7️⃣  Eliminar Producto"
    
    $deleteResult = Test-ApiEndpoint `
        -Method "DELETE" `
        -Endpoint "/api/v1/products/$createdProductId" `
        -Description "Eliminar producto con ID: $createdProductId"
    
    # Verificar que se eliminó
    Write-Host "`n🔍 Verificando eliminación..." -ForegroundColor Yellow
    
    $verifyResult = Test-ApiEndpoint `
        -Method "GET" `
        -Endpoint "/api/v1/products/$createdProductId" `
        -Description "Intentar obtener producto eliminado"
    
    if (-not $verifyResult.Success) {
        Write-ColorOutput "   ✅ Producto eliminado correctamente (404 esperado)" "Green"
    } else {
        Write-ColorOutput "   ⚠️  El producto aún existe" "Yellow"
    }
}

# ============================================
# 8. Pruebas adicionales de validación
# ============================================
Write-SectionHeader "8️⃣  Pruebas de Validación"

Write-Host "`n🔍 Crear producto con datos inválidos (sin nombre)" -ForegroundColor Yellow

$invalidProduct = @{
    description = "Producto sin nombre"
    price = 99.99
}

$invalidResult = Test-ApiEndpoint `
    -Method "POST" `
    -Endpoint "/api/v1/products" `
    -Description "Intentar crear producto sin nombre (debe fallar)" `
    -Body $invalidProduct

if (-not $invalidResult.Success) {
    Write-ColorOutput "   ✅ Validación funcionando correctamente (error esperado)" "Green"
}

# ============================================
# Resumen final
# ============================================
Write-SectionHeader "📊 RESUMEN DE PRUEBAS"

$testResults = @(
    @{ Name = "Health Check"; Result = $healthResult },
    @{ Name = "Listar Productos"; Result = $listResult },
    @{ Name = "Crear Producto"; Result = $createResult },
    @{ Name = "Obtener Producto"; Result = $getResult },
    @{ Name = "Actualizar Producto"; Result = $updateResult },
    @{ Name = "Buscar Productos"; Result = $searchResult },
    @{ Name = "Eliminar Producto"; Result = $deleteResult },
    @{ Name = "Validación"; Result = $invalidResult }
)

$successCount = 0
$failCount = 0
$totalDuration = 0

Write-Host ""
foreach ($test in $testResults) {
    if ($test.Result) {
        Write-Host "   $($test.Name): " -NoNewline
        
        if ($test.Result.Success) {
            Write-ColorOutput "✅ Success" "Green"
            $successCount++
            if ($test.Result.Duration) {
                $totalDuration += $test.Result.Duration
            }
        } else {
            Write-ColorOutput "❌ Failed" "Red"
            $failCount++
        }
    }
}

Write-Host ""
Write-ColorOutput "Pruebas exitosas: $successCount" "Green"
if ($failCount -gt 0) {
    Write-ColorOutput "Pruebas fallidas: $failCount" "Red"
}
Write-ColorOutput "Tiempo total: $([Math]::Round($totalDuration, 2))ms" "Gray"

# ============================================
# Recomendaciones
# ============================================
if ($failCount -gt 0) {
    Write-ColorOutput "`n💡 Recomendaciones:" "Yellow"
    Write-ColorOutput "   1. Verifica que la aplicación esté corriendo" "White"
    Write-ColorOutput "   2. Revisa los logs del backend:" "White"
    Write-ColorOutput "      docker logs -f springboot-local" "Gray"
    Write-ColorOutput "      kubectl logs -f deployment/backend-products -n springboot-products" "Gray"
    Write-ColorOutput "   3. Verifica la conectividad con la base de datos" "White"
    Write-ColorOutput "   4. Ejecuta diagnóstico: .\diagnose.ps1" "White"
} else {
    Write-ColorOutput "`n✅ Todos los endpoints funcionan correctamente" "Green"
    Write-ColorOutput "🎉 La API está lista para usar" "Green"
}

Write-Host "`n"