# ☸️ Scripts de Kubernetes

Scripts para despliegue y gestión en Kubernetes (Docker Desktop y Azure AKS).

---

## 📋 Scripts disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`deploy-local.ps1`** | Desplegar en Docker Desktop (Kubernetes local) | `.\deploy-local.ps1` |
| **`deploy-aks.ps1`** | Desplegar en Azure Kubernetes Service | `.\deploy-aks.ps1 -ResourceGroup "rg" -ClusterName "aks"` |
| **`deploy-k8s.ps1`** | Despliegue genérico (detecta contexto automáticamente) | `.\deploy-k8s.ps1` |
| `build-and-push.ps1` | Construir y subir imagen a ACR | `.\build-and-push.ps1 -ACRName "miacr" -Tag "v1.0.0"` |
| `delete-k8s.ps1` | Eliminar recursos de Kubernetes | `.\delete-k8s.ps1` |
| `generate-secrets.ps1` | Generar secrets en base64 | `.\generate-secrets.ps1` |

---

## 🚀 Guías de uso

### **1. Despliegue Local (Docker Desktop)**

#### **Requisitos previos:**
```powershell
# Habilitar Kubernetes en Docker Desktop:
# Settings → Kubernetes → Enable Kubernetes → Apply & Restart
```

#### **Desplegar:**
```powershell
# Opción 1: Script dedicado
.\deploy-local.ps1

# Opción 2: Script genérico (detecta automáticamente)
.\deploy-k8s.ps1
```

#### **Qué hace:**
1. ✅ Construye imagen Docker local
2. ✅ Crea namespace `springboot-products`
3. ✅ Aplica ConfigMaps y Secrets
4. ✅ Despliega MySQL con PersistentVolume
5. ✅ Despliega Backend
6. ✅ Crea Services

#### **Acceder a la aplicación:**
```powershell
# Port-forward del servicio
kubectl port-forward svc/backend-service 8080:80 -n springboot-products

# Abrir en navegador
Start-Process "http://localhost:8080/actuator/health"
```

---

### **2. Despliegue en Azure AKS**

#### **Requisitos previos:**
```powershell
# Instalar Azure CLI
winget install Microsoft.AzureCLI

# Autenticar
az login

# Crear recursos (si no existen)
az group create --name rg-springboot-products --location eastus
az acr create --resource-group rg-springboot-products --name acrspringboot --sku Basic
az aks create --resource-group rg-springboot-products --name aks-springboot --node-count 2
```

#### **Desplegar:**
```powershell
# Con parámetros por defecto
.\deploy-aks.ps1

# Con parámetros personalizados
.\deploy-aks.ps1 `
    -ResourceGroup "mi-resource-group" `
    -ClusterName "mi-aks-cluster" `
    -ACRName "miacr"
```

#### **Qué hace:**
1. ✅ Verifica autenticación Azure
2. ✅ Obtiene credenciales de AKS
3. ✅ Construye imagen Docker
4. ✅ Sube imagen a Azure Container Registry
5. ✅ Despliega MySQL y Backend
6. ✅ Configura Ingress y HPA
7. ✅ Obtiene IP pública

#### **Acceder a la aplicación:**
```powershell
# Obtener IP del Ingress
kubectl get ingress -n springboot-products

# Acceder via IP
Start-Process "http://<IP-PUBLICA>/actuator/health"

# Configurar DNS (en tu proveedor)
# A record: api.tudominio.com → <IP-PUBLICA>
```

---

### **3. Generar Secrets**

#### **Antes del primer despliegue:**
```powershell
.\generate-secrets.ps1
```

#### **Proceso interactivo:**
1. Te pedirá:
   - MySQL Root Password
   - MySQL Database Name
   - MySQL User
   - MySQL Password
2. Generará automáticamente JWT Secret
3. Creará `K8s/base/secrets.yaml` con valores en base64
4. Agregará el archivo a `.gitignore`

#### **Aplicar secrets manualmente:**
```powershell
kubectl apply -f ..\..\K8s\base\secrets.yaml
```

#### **Ver secrets decodificados:**
```powershell
# Ver todos los secrets
kubectl get secret backend-secrets -n springboot-products -o yaml

# Decodificar un secret específico
kubectl get secret backend-secrets -n springboot-products -o jsonpath='{.data.MYSQL_USER}' | base64 --decode
```

---

### **4. Build and Push a ACR**

#### **Construir y subir imagen:**
```powershell
# Con tag automático (timestamp)
.\build-and-push.ps1 -ACRName "acrspringbootproducts"

# Con tag específico
.\build-and-push.ps1 -ACRName "acrspringbootproducts" -Tag "v1.0.0"
```

#### **Ver imágenes en ACR:**
```powershell
# Listar repositorios
az acr repository list --name acrspringbootproducts --output table

# Ver tags de una imagen
az acr repository show-tags --name acrspringbootproducts --repository springboot-products --output table
```

#### **Actualizar deployment con nueva imagen:**
```powershell
# Actualizar imagen en deployment existente
kubectl set image deployment/backend-products `
    backend=acrspringbootproducts.azurecr.io/springboot-products:v1.0.0 `
    -n springboot-products

# Verificar rollout
kubectl rollout status deployment/backend-products -n springboot-products
```

---

### **5. Eliminar recursos**

#### **Eliminar todo:**
```powershell
# Opción 1: Eliminar namespace completo
.\delete-k8s.ps1 -DeleteNamespace

# Opción 2: Menú interactivo
.\delete-k8s.ps1
```

#### **Eliminar selectivamente:**
```powershell
# Solo Backend
.\delete-k8s.ps1 -DeleteBackend

# Solo MySQL (⚠️ se pierden datos)
.\delete-k8s.ps1 -DeleteMySQL
```

---

## 🎯 Flujos de trabajo comunes

### **Desarrollo Local**

```powershell
# 1. Primera vez: generar secrets
.\generate-secrets.ps1

# 2. Desplegar
.\deploy-local.ps1

# 3. Ver logs
kubectl logs -f deployment/backend-products -n springboot-products

# 4. Acceder
kubectl port-forward svc/backend-service 8080:80 -n springboot-products
```

### **Despliegue en Azure**

```powershell
# 1. Construir y subir imagen
.\build-and-push.ps1 -ACRName "miacr" -Tag "v1.0.0"

# 2. Desplegar en AKS
.\deploy-aks.ps1 -ResourceGroup "mi-rg" -ClusterName "mi-aks" -ACRName "miacr"

# 3. Verificar despliegue
kubectl get all -n springboot-products

# 4. Obtener IP
kubectl get ingress -n springboot-products
```

### **Actualizar imagen en AKS**

```powershell
# 1. Construir nueva versión
.\build-and-push.ps1 -ACRName "miacr" -Tag "v1.0.1"

# 2. Actualizar deployment
kubectl set image deployment/backend-products `
    backend=miacr.azurecr.io/springboot-products:v1.0.1 `
    -n springboot-products

# 3. Monitorear rollout
kubectl rollout status deployment/backend-products -n springboot-products
```

---

## 📊 Comandos útiles de Kubernetes

### **Ver recursos:**
```powershell
# Todo en el namespace
kubectl get all -n springboot-products

# Solo pods
kubectl get pods -n springboot-products

# Solo services
kubectl get svc -n springboot-products

# Ingress y HPA
kubectl get ingress,hpa -n springboot-products

# Persistent Volumes
kubectl get pvc -n springboot-products
```

### **Logs:**
```powershell
# Backend (tiempo real)
kubectl logs -f deployment/backend-products -n springboot-products

# MySQL
kubectl logs -f deployment/mysql -n springboot-products

# Últimas 100 líneas
kubectl logs deployment/backend-products -n springboot-products --tail=100
```

### **Describir recursos:**
```powershell
# Describir pod (útil para troubleshooting)
kubectl describe pod <pod-name> -n springboot-products

# Describir deployment
kubectl describe deployment backend-products -n springboot-products

# Describir service
kubectl describe svc backend-service -n springboot-products
```

### **Ejecutar comandos en pods:**
```powershell
# Shell interactivo en el backend
kubectl exec -it deployment/backend-products -n springboot-products -- bash

# Ejecutar comando específico
kubectl exec deployment/backend-products -n springboot-products -- env | grep SPRING

# MySQL CLI
kubectl exec -it deployment/mysql -n springboot-products -- mysql -u root -p
```

### **Port forwarding:**
```powershell
# Backend
kubectl port-forward svc/backend-service 8080:80 -n springboot-products

# MySQL (para conexión con cliente)
kubectl port-forward svc/mysql-service 3306:3306 -n springboot-products
```

### **Escalar recursos:**
```powershell
# Escalar backend manualmente
kubectl scale deployment backend-products --replicas=3 -n springboot-products

# Ver HPA (auto-scaling)
kubectl get hpa -n springboot-products
kubectl describe hpa backend-hpa -n springboot-products
```

---

## 🐛 Troubleshooting

### **Pod no inicia (CrashLoopBackOff)**

```powershell
# 1. Ver logs del pod
kubectl logs <pod-name> -n springboot-products

# 2. Ver eventos
kubectl describe pod <pod-name> -n springboot-products

# 3. Verificar secrets y configmaps
kubectl get secret backend-secrets -n springboot-products
kubectl get configmap backend-config -n springboot-products

# 4. Verificar imagen
kubectl get deployment backend-products -n springboot-products -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### **No se puede conectar a MySQL**

```powershell
# 1. Verificar que MySQL está corriendo
kubectl get pods -l app=mysql -n springboot-products

# 2. Verificar service
kubectl get svc mysql-service -n springboot-products

# 3. Verificar DNS interno
kubectl exec deployment/backend-products -n springboot-products -- nslookup mysql-service

# 4. Ver logs de MySQL
kubectl logs deployment/mysql -n springboot-products
```

### **Imagen no se descarga de ACR**

```powershell
# 1. Verificar que la imagen existe en ACR
az acr repository show-tags --name <acr-name> --repository springboot-products

# 2. Verificar autenticación (AKS debe tener permisos en ACR)
az aks check-acr --resource-group <rg> --name <aks-name> --acr <acr-name>.azurecr.io

# 3. Crear role assignment si falta
az aks update --resource-group <rg> --name <aks-name> --attach-acr <acr-name>
```

### **Ingress no obtiene IP pública**

```powershell
# 1. Verificar Ingress Controller está instalado
kubectl get pods -n ingress-nginx

# 2. Instalar si falta (AKS)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# 3. Esperar a que se asigne IP
kubectl get ingress -n springboot-products -w
```

---

## 📚 Referencias

### **Kubernetes:**
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### **Azure AKS:**
- [Azure AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)

### **Manifiestos del proyecto:**
- [K8s/README.md](../../K8s/README.md) - Documentación de manifiestos
- [K8s/base/](../../K8s/base/) - Configuración base
- [K8s/local/](../../K8s/local/) - Configuración Docker Desktop
- [K8s/azure/](../../K8s/azure/) - Configuración AKS

---

## 💡 Tips y mejores prácticas

1. ✅ **Usa `generate-secrets.ps1` antes del primer despliegue**
2. ✅ **Prueba localmente con Docker Desktop antes de AKS**
3. ✅ **Usa tags semánticos para imágenes** (`v1.0.0`, no `latest`)
4. ✅ **Revisa logs con `kubectl logs -f` para troubleshooting**
5. ✅ **Usa `kubectl describe` para ver eventos y problemas**
6. ⚠️ **NO subas `secrets.yaml` a Git**
7. ⚠️ **Configura límites de recursos (requests/limits) en producción**
8. ⚠️ **Usa Azure Key Vault para secrets en producción**

---

## 🆘 Obtener ayuda

```powershell
# Ayuda de un script
Get-Help .\deploy-local.ps1 -Full

# Listar todos los scripts
..\utils\list-scripts.ps1

# Diagnosticar problemas
..\utils\diagnose.ps1
```