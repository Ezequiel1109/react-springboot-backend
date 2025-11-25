# Prueba exhaustiva para el manejo de errores JSON

Write-Host "=== INICIANDO PRUEBAS DE JSON ==="

# Función para hacer peticiones de forma segura
function Test-JsonRequest {
    param(
        [string]$TestName,
        [string]$Url,
        [string]$JsonBody
    )
    
    Write-Host "`n=== $TestName ==="
    Write-Host "JSON enviado: $JsonBody"
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method POST -ContentType "application/json" -Body $JsonBody -ErrorAction Stop
        Write-Host "✅ Éxito: Código $($response.StatusCode)"
        Write-Host "Respuesta: $($response.Content)"
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "Detalle del error: $responseBody"
        }
    }
}

# Prueba 1: JSON correcto
Test-JsonRequest "PRODUCTO CON JSON CORRECTO" "http://localhost:8080/product" '{"name":"Test Product","price":100,"quantity":10,"description":"Test description"}'

# Prueba 2: Números como strings (común en formularios web)
Test-JsonRequest "PRODUCTO CON NÚMEROS COMO STRINGS" "http://localhost:8080/product" '{"name":"Test Product 2","price":"150","quantity":"5","description":"Test with string numbers"}'

# Prueba 3: JSON con campo anidado (el que causa problemas)
Test-JsonRequest "PRODUCTO CON OBJETO ANIDADO EN PRICE" "http://localhost:8080/product" '{"name":"Test Product 3","price":{"value":200,"currency":"USD"},"quantity":15,"description":"Test with nested object"}'

# Prueba 4: JSON con campos extra (debería ignorarse)
Test-JsonRequest "PRODUCTO CON CAMPOS EXTRA" "http://localhost:8080/product" '{"name":"Test Product 4","price":300,"quantity":20,"description":"Test with extra fields","extraField":"ignored","category":"electronics"}'

# Prueba 5: User registration (JSON correcto)
Test-JsonRequest "USUARIO REGISTRO CORRECTO" "http://localhost:8080/user/register" '{"username":"testuser","password":"testpass","email":"test@example.com"}'

# Prueba 6: User con campos anidados
Test-JsonRequest "USUARIO CON OBJETO ANIDADO" "http://localhost:8080/user/register" '{"username":{"first":"test","last":"user"},"password":"testpass2","email":"test2@example.com"}'

Write-Host "`n=== PRUEBAS COMPLETADAS ==="
