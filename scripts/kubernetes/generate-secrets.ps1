<#
.SYNOPSIS
    Genera secrets en base64 para Kubernetes de forma interactiva

.DESCRIPTION
    Script interactivo para generar secrets seguros en base64 para:
    - MySQL (root password, database, user, password)
    - Spring Boot (datasource credentials)
    - JWT Secret (generado aleatoriamente)
    
    Genera automáticamente el archivo k8s/base/secrets.yaml

.EXAMPLE
    .\generate-secrets.ps1
#>

$ErrorActionPreference = "Stop"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function ConvertTo-Base64($text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    return [Convert]::ToBase64String($bytes)
}

function Read-SecurePassword($prompt) {
    $secureString = Read-Host $prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $plainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    return $plainText
}

function New-RandomPassword($length = 32) {
    $bytes = New-Object byte[] $length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

# ============================================
# Banner
# ============================================
Write-ColorOutput "`n🔐 Generador de Secrets para Kubernetes" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n⚠️  IMPORTANTE:" "Yellow"
Write-ColorOutput "   - Los secrets generados se guardarán en k8s/base/secrets.yaml" "White"
Write-ColorOutput "   - NO subas este archivo a Git (debe estar en .gitignore)" "Red"
Write-ColorOutput "   - Usa contraseñas seguras para producción" "White"

Write-ColorOutput "`n📋 Valores que se configurarán:" "Cyan"
Write-ColorOutput "   1. MySQL Root Password" "White"
Write-ColorOutput "   2. MySQL Database Name" "White"
Write-ColorOutput "   3. MySQL User" "White"
Write-ColorOutput "   4. MySQL Password" "White"
Write-ColorOutput "   5. JWT Secret (generado automáticamente)" "White"

Write-Host "`nPresiona Enter para continuar..." -ForegroundColor Yellow
Read-Host

# ============================================
# Recopilar datos
# ============================================
$secrets = @{}

# MySQL Root Password
Write-ColorOutput "`n🔑 MySQL Root Password" "Green"
Write-ColorOutput "   (mínimo 8 caracteres, recomendado: 16+)" "Gray"
$mysqlRoot = Read-SecurePassword "Ingresa password"

if ($mysqlRoot.Length -lt 8) {
    Write-ColorOutput "⚠️  Contraseña muy corta. Usando generada aleatoriamente..." "Yellow"
    $mysqlRoot = New-RandomPassword -length 16
    Write-ColorOutput "   Password generada: $mysqlRoot" "Gray"
}

$secrets['MYSQL_ROOT_PASSWORD'] = ConvertTo-Base64 $mysqlRoot

# MySQL Database
Write-ColorOutput "`n🗄️  MySQL Database Name" "Green"
Write-ColorOutput "   (ejemplo: db_backend_crud)" "Gray"
$dbName = Read-Host "Ingresa nombre"

if ([string]::IsNullOrWhiteSpace($dbName)) {
    $dbName = "db_backend_crud"
    Write-ColorOutput "   Usando valor por defecto: $dbName" "Yellow"
}

$secrets['MYSQL_DATABASE'] = ConvertTo-Base64 $dbName

# MySQL User
Write-ColorOutput "`n👤 MySQL User" "Green"
Write-ColorOutput "   (ejemplo: springboot)" "Gray"
$dbUser = Read-Host "Ingresa usuario"

if ([string]::IsNullOrWhiteSpace($dbUser)) {
    $dbUser = "springboot"
    Write-ColorOutput "   Usando valor por defecto: $dbUser" "Yellow"
}

$secrets['MYSQL_USER'] = ConvertTo-Base64 $dbUser
$secrets['SPRING_DATASOURCE_USERNAME'] = ConvertTo-Base64 $dbUser

# MySQL Password
Write-ColorOutput "`n🔑 MySQL User Password" "Green"
Write-ColorOutput "   (mínimo 8 caracteres)" "Gray"
$dbPassword = Read-SecurePassword "Ingresa password"

if ($dbPassword.Length -lt 8) {
    Write-ColorOutput "⚠️  Contraseña muy corta. Usando generada aleatoriamente..." "Yellow"
    $dbPassword = New-RandomPassword -length 16
    Write-ColorOutput "   Password generada: $dbPassword" "Gray"
}

$secrets['MYSQL_PASSWORD'] = ConvertTo-Base64 $dbPassword
$secrets['SPRING_DATASOURCE_PASSWORD'] = ConvertTo-Base64 $dbPassword

# JWT Secret (generado automáticamente)
Write-ColorOutput "`n🔐 JWT Secret" "Green"
Write-ColorOutput "   Generando secret aleatorio (256 bits)..." "Gray"
$jwtSecret = New-RandomPassword -length 32
$secrets['JWT_SECRET'] = $jwtSecret
Write-ColorOutput "   ✅ Generado" "Green"

# ============================================
# Mostrar resumen (sin mostrar passwords)
# ============================================
Write-ColorOutput "`n📊 Resumen de configuración:" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`nMySQL Root Password:" "Yellow"
Write-ColorOutput "   Base64: $($secrets['MYSQL_ROOT_PASSWORD'])" "Gray"

Write-ColorOutput "`nMySQL Database:" "Yellow"
Write-ColorOutput "   Valor:  $dbName" "White"
Write-ColorOutput "   Base64: $($secrets['MYSQL_DATABASE'])" "Gray"

Write-ColorOutput "`nMySQL User:" "Yellow"
Write-ColorOutput "   Valor:  $dbUser" "White"
Write-ColorOutput "   Base64: $($secrets['MYSQL_USER'])" "Gray"

Write-ColorOutput "`nMySQL Password:" "Yellow"
Write-ColorOutput "   Base64: $($secrets['MYSQL_PASSWORD'])" "Gray"

Write-ColorOutput "`nSpring Datasource Username:" "Yellow"
Write-ColorOutput "   Base64: $($secrets['SPRING_DATASOURCE_USERNAME'])" "Gray"

Write-ColorOutput "`nSpring Datasource Password:" "Yellow"
Write-ColorOutput "   Base64: $($secrets['SPRING_DATASOURCE_PASSWORD'])" "Gray"

Write-ColorOutput "`nJWT Secret:" "Yellow"
Write-ColorOutput "   Base64: $($secrets['JWT_SECRET'])" "Gray"

# ============================================
# Generar archivo secrets.yaml
# ============================================
Write-ColorOutput "`n📝 ¿Generar archivo k8s/base/secrets.yaml? (y/n)" "Yellow"
$generate = Read-Host

if ($generate -eq "y" -or $generate -eq "Y" -or $generate -eq "") {
    
    $secretsPath = "..\..\K8s\base\secrets.yaml"
    
    # Verificar si existe y hacer backup
    if (Test-Path $secretsPath) {
        $backupPath = "$secretsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $secretsPath $backupPath
        Write-ColorOutput "💾 Backup creado: $backupPath" "Yellow"
    }
    
    # Contenido del archivo
    $secretsContent = @"
# ============================================
# Kubernetes Secrets
# ============================================
# ⚠️ NO SUBIR A GIT - Agregar a .gitignore
# Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# ============================================

apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: springboot-products
type: Opaque
data:
  # MySQL Secrets
  MYSQL_ROOT_PASSWORD: $($secrets['MYSQL_ROOT_PASSWORD'])
  MYSQL_DATABASE: $($secrets['MYSQL_DATABASE'])
  MYSQL_USER: $($secrets['MYSQL_USER'])
  MYSQL_PASSWORD: $($secrets['MYSQL_PASSWORD'])
  
  # Spring Boot Datasource
  SPRING_DATASOURCE_USERNAME: $($secrets['SPRING_DATASOURCE_USERNAME'])
  SPRING_DATASOURCE_PASSWORD: $($secrets['SPRING_DATASOURCE_PASSWORD'])
  
  # JWT Secret
  JWT_SECRET: $($secrets['JWT_SECRET'])
"@

    # Crear directorio si no existe
    $secretsDir = Split-Path -Parent $secretsPath
    if (-not (Test-Path $secretsDir)) {
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
    }
    
    # Guardar archivo
    $secretsContent | Out-File -FilePath $secretsPath -Encoding UTF8
    
    Write-ColorOutput "`n✅ Archivo creado exitosamente" "Green"
    Write-ColorOutput "   Ubicación: $secretsPath" "Gray"
    
    # Verificar .gitignore
    $gitignorePath = "..\..\..\.gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath -Raw
        if (-not $gitignoreContent.Contains("secrets.yaml")) {
            Write-ColorOutput "`n⚠️  Agregando secrets.yaml a .gitignore..." "Yellow"
            Add-Content -Path $gitignorePath -Value "`n# Kubernetes Secrets (NO SUBIR A GIT)`nK8s/base/secrets.yaml"
            Write-ColorOutput "✅ Agregado a .gitignore" "Green"
        }
    }
    
} else {
    Write-ColorOutput "`n❌ Operación cancelada" "Yellow"
}

# ============================================
# Instrucciones finales
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "✅ GENERACIÓN COMPLETADA" "Green"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n💡 Próximos pasos:" "Cyan"
Write-ColorOutput "   1. Verifica que secrets.yaml está en .gitignore" "White"
Write-ColorOutput "   2. Aplica los secrets en Kubernetes:" "White"
Write-ColorOutput "      kubectl apply -f K8s/base/secrets.yaml" "Gray"
Write-ColorOutput "   3. Verifica los secrets creados:" "White"
Write-ColorOutput "      kubectl get secrets -n springboot-products" "Gray"
Write-ColorOutput "   4. Para ver un secret decodificado:" "White"
Write-ColorOutput "      kubectl get secret backend-secrets -n springboot-products -o jsonpath='{.data.MYSQL_USER}' | base64 --decode" "Gray"

Write-ColorOutput "`n⚠️  SEGURIDAD:" "Yellow"
Write-ColorOutput "   - Guarda las contraseñas en un gestor seguro (1Password, LastPass, etc.)" "White"
Write-ColorOutput "   - NO compartas el archivo secrets.yaml" "Red"
Write-ColorOutput "   - Para producción, considera usar Azure Key Vault" "White"

Write-ColorOutput "`n📚 Documentación:" "Cyan"
Write-ColorOutput "   - Kubernetes Secrets: https://kubernetes.io/docs/concepts/configuration/secret/" "Gray"
Write-ColorOutput "   - Azure Key Vault: https://azure.microsoft.com/services/key-vault/" "Gray"

Write-ColorOutput "`n"