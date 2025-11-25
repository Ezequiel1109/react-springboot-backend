<#
.SYNOPSIS
    Despliega la aplicación en Docker Desktop Kubernetes (desarrollo local)

.DESCRIPTION
    Script completo para desplegar en Kubernetes local usando Docker Desktop.
    Incluye MySQL, backend y configuración de red.

.EXAMPLE
    .\deploy-local.ps1
#>

$ErrorActionPreference = "Stop"

$NAMESPACE = "springboot-products"
$K8S_PATH = "..\..\K8s"

# ============================================
# Funciones auxiliares
# ============================================
function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}
function Test-KubernetesRunning {
    try {
        kubectl version --client --short | Out-Null
        return $true
    } catch {
        Write-ColorOutput "❌ kubectl no está disponible" "Red"
        return $false
    }
}

function Switch-ToDockerDesktop {
    $context = kubectl config current-context
    
    if ($context -ne "docker-desktop") {
        Write-ColorOutput "⚠️  Contexto actual: $context" "Yellow"
        Write-ColorOutput "🔄 Cambiando a docker-desktop..." "Yellow"
        
        kubectl config use-context docker-desktop
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Error al cambiar contexto" "Red"
            Write-ColorOutput "   ¿Está Kubernetes habilitado en Docker Desktop?" "Yellow"
            exit 1
        }
        
        Write-ColorOutput "✅ Contexto cambiado a docker-desktop" "Green"
    } else {
        Write-ColorOutput "✅ Ya estás en el contexto docker-desktop" "Green"
    }
}

# ============================================
# Main
# ============================================
Write-ColorOutput "☸️  Desplegando en Docker Desktop Kubernetes" "Cyan"
Write-ColorOutput "=" * 70 "Gray"

# Verificar kubectl
if (-not (Test-KubernetesRunning)) {
    Write-ColorOutput "💡 Instala kubectl o habilita Kubernetes en Docker Desktop" "Yellow"
    exit 1
}

# Cambiar a contexto docker-desktop
Switch-ToDockerDesktop

# ============================================
# Paso 1: Construir imagen local
# ============================================
Write-ColorOutput "`n🔨 Paso 1/6: Construyendo imagen Docker local..." "Green"

docker build -t springboot-products:local .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Error al construir imagen" "Red"
    exit 1
}

$imageSize = docker images springboot-products:local --format "{{.Size}}"
Write-ColorOutput "✅ Imagen construida: springboot-products:local ($imageSize)" "Green"

# ============================================
# Paso 2: Crear namespace
# ============================================
Write-ColorOutput "`n📦 Paso 2/6: Creando namespace..." "Green"

kubectl apply -f "$K8S_PATH\base\namespace.yaml"
Write-ColorOutput "✅ Namespace '$NAMESPACE' creado/actualizado" "Green"

# ============================================
# Paso 3: Aplicar ConfigMap y Secrets
# ============================================
Write-ColorOutput "`n🔧 Paso 3/6: Aplicando configuración..." "Green"

kubectl apply -f "$K8S_PATH\base\configmap.yaml"
Write-ColorOutput "✅ ConfigMap aplicado" "Green"

# Verificar si secrets.yaml existe
if (Test-Path "$K8S_PATH\base\secrets.yaml") {
    kubectl apply -f "$K8S_PATH\base\secrets.yaml"
    Write-ColorOutput "✅ Secrets aplicados" "Green"
} else {
    Write-ColorOutput "⚠️  secrets.yaml no encontrado" "Yellow"
    Write-ColorOutput "   Ejecuta: ..\generate-secrets.ps1" "Yellow"
    exit 1
}

# ============================================
# Paso 4: Desplegar MySQL
# ============================================
Write-ColorOutput "`n🗄️  Paso 4/6: Desplegando MySQL..." "Green"

kubectl apply -f "$K8S_PATH\mysql\mysql-pvc.yaml"
kubectl apply -f "$K8S_PATH\mysql\mysql-deployment.yaml"
kubectl apply -f "$K8S_PATH\mysql\mysql-service.yaml"

Write-ColorOutput "⏳ Esperando a que MySQL esté listo (puede tardar 2-3 minutos)..." "Yellow"
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "✅ MySQL está listo" "Green"
} else {
    Write-ColorOutput "❌ Timeout esperando MySQL" "Red"
    Write-ColorOutput "📝 Ver logs: kubectl logs -l app=mysql -n $NAMESPACE" "Yellow"
    exit 1
}

# ============================================
# Paso 5: Desplegar Backend
# ============================================
Write-ColorOutput "`n🚀 Paso 5/6: Desplegando Backend..." "Green"

kubectl apply -f "$K8S_PATH\local\backend-deployment-local.yaml"
kubectl apply -f "$K8S_PATH\backend-service.yaml"
Write-ColorOutput "⏳ Esperando a que Backend esté listo..." "Yellow"
kubectl wait --for=condition=ready pod -l app=backend-products -n $NAMESPACE --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "✅ Backend está listo" "Green"
} else {
    Write-ColorOutput "❌ Timeout esperando Backend" "Red"
    Write-ColorOutput "📝 Ver logs: kubectl logs -l app=backend-products -n $NAMESPACE" "Yellow"
    exit 1
}

# ============================================
# Paso 6: Mostrar estado final
# ============================================
Write-ColorOutput "`n📊 Paso 6/6: Verificando despliegue..." "Green"

Write-ColorOutput "`n📦 Pods:" "Cyan"
kubectl get pods -n $NAMESPACE

Write-ColorOutput "`n🌐 Servicios:" "Cyan"
kubectl get svc -n $NAMESPACE

Write-ColorOutput "`n💾 Persistent Volumes:" "Cyan"
kubectl get pvc -n $NAMESPACE

# ============================================
# Instrucciones de acceso
# ============================================
Write-ColorOutput "`n" "Gray"
Write-ColorOutput "=" * 70 "Gray"
Write-ColorOutput "✅ DESPLIEGUE COMPLETADO EXITOSAMENTE" "Green"
Write-ColorOutput "=" * 70 "Gray"

Write-ColorOutput "`n🌐 Para acceder a la aplicación:" "Cyan"
Write-ColorOutput "   1. Ejecuta en otra terminal:" "White"
Write-ColorOutput "      kubectl port-forward svc/backend-service 9090:90 -n $NAMESPACE" "Yellow"
Write-ColorOutput "`n   2. Abre en el navegador:" "White"
Write-ColorOutput "      http://localhost:9090" "Cyan"
Write-ColorOutput "      http://localhost:9090/actuator/health" "Cyan"

Write-ColorOutput "`n📝 Ver logs en tiempo real:" "Cyan"
Write-ColorOutput "   Backend: kubectl logs -f deployment/backend-products -n $NAMESPACE" "White"
Write-ColorOutput "   MySQL:   kubectl logs -f deployment/mysql -n $NAMESPACE" "White"

Write-ColorOutput "`n🔍 Comandos útiles:" "Cyan"
Write-ColorOutput "   Ver pods:     kubectl get pods -n $NAMESPACE" "White"
Write-ColorOutput "   Ver servicios: kubectl get svc -n $NAMESPACE" "White"
Write-ColorOutput "   Describir pod: kubectl describe pod <pod-name> -n $NAMESPACE" "White"
Write-ColorOutput "   Ejecutar shell: kubectl exec -it <pod-name> -n $NAMESPACE -- bash" "White"

Write-ColorOutput "`n🛑 Para eliminar todo:" "Yellow"
Write-ColorOutput "   kubectl delete namespace $NAMESPACE" "White"
Write-ColorOutput "   O ejecuta: ..\delete-k8s.ps1" "White"

Write-ColorOutput "`n"