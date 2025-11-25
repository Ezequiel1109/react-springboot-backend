# 🛠️ Scripts de Utilidad

Herramientas de soporte para diagnóstico, configuración y testing del proyecto.

---

## 📋 Scripts disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`setup-environment.ps1`** | Configura el entorno de desarrollo completo | `.\setup-environment.ps1` |
| `diagnose.ps1` | Diagnostica problemas del proyecto | `.\diagnose.ps1` |
| `cleanup.ps1` | Limpia recursos de Docker y Kubernetes | `.\cleanup.ps1 -All` |
| `list-scripts.ps1` | Lista todos los scripts disponibles | `.\list-scripts.ps1` |
| `test-api-requests.ps1` | Prueba los endpoints de la API | `.\test-api-requests.ps1` |

---

## 🚀 Guías de uso

### **setup-environment.ps1** - Primera vez

Script **recomendado para comenzar** con el proyecto. Te guía paso a paso para configurar todo el entorno.

```powershell
.\setup-environment.ps1
```

#### **Qué hace:**
1. ✅ Verifica e instala herramientas necesarias:
   - Docker Desktop
   - Java (OpenJDK 21)
   - Maven
   - kubectl
   - Azure CLI
   - Git

2. ✅ Configura Docker Desktop:
   - Verifica que Docker esté corriendo
   - Verifica que Kubernetes esté habilitado

3. ✅ Configura Azure (opcional):
   - Autenticación con Azure CLI

4. ✅ Genera secrets de Kubernetes:
   - Ejecuta `generate-secrets.ps1` automáticamente

5. ✅ Crea archivo `.env` local:
   - Variables de entorno para desarrollo

6. ✅ Verifica estructura del proyecto:
   - Archivos y carpetas necesarios

#### **Resultado:**
Al finalizar, tendrás todo listo para:
- Ejecutar la aplicación localmente
- Desplegarla en Kubernetes
- Desarrollar nuevas funcionalidades

---

### **diagnose.ps1** - Solución de problemas

Diagnostica problemas comunes del proyecto.

```powershell
.\diagnose.ps1
```

#### **Qué verifica:**
1. **Herramientas instaladas:**
   - Docker, kubectl, Java, Maven, Azure CLI, Git
   - Versiones de cada herramienta

2. **Docker:**
   - Estado del servicio
   - Contenedores del proyecto
   - Imágenes disponibles
   - Uso de recursos

3. **Kubernetes:**
   - Contexto actual
   - Conectividad con cluster
   - Estado de pods
   - Services, ConfigMaps, Secrets
   - Logs de pods con problemas

4. **Proyecto:**
   - Estructura de carpetas
   - Archivos importantes
   - Configuración de Spring Boot

5. **Conectividad:**
   - Internet
   - Docker Hub
   - Azure (si está configurado)

#### **Salida ejemplo:**
```
🔧 Verificando herramientas instaladas
========================================
Docker: ✅ Instalado (v24.0.5)
Java: ✅ Instalado (OpenJDK 21.0.1)
Maven: ✅ Instalado (3.9.5)
kubectl: ✅ Instalado (v1.28.2)
Azure CLI: ✅ Instalado (2.53.0)

🐳 Diagnóstico de Docker
========================
Estado de Docker: ✅ Corriendo
Contenedores: springboot-local (Up 2 hours)
Imágenes: springboot-products:local (350MB)

☸️ Diagnóstico de Kubernetes
============================
Contexto actual: docker-desktop ✅
Pods: backend-products-xxx Running ✅
      mysql-xxx Running ✅
```

#### **Cuándo usarlo:**
- ❌ La aplicación no inicia
- ❌ Errores en despliegues
- ❌ Problemas de conectividad
- ❌ Antes de reportar un bug

---

### **cleanup.ps1** - Limpieza de recursos

Limpia recursos de Docker y Kubernetes del proyecto.

```powershell
# Limpiar todo
.\cleanup.ps1 -All

# Solo Docker
.\cleanup.ps1 -Docker

# Solo Kubernetes
.\cleanup.ps1 -Kubernetes

# Solo archivos temporales
.\cleanup.ps1 -TempFiles

# Menú interactivo
.\cleanup.ps1
```

#### **Qué limpia:**

##### **Docker (`-Docker`):**
- Detiene y elimina contenedores
- Elimina imágenes del proyecto
- Elimina volúmenes
- Limpia recursos no utilizados

##### **Kubernetes (`-Kubernetes`):**
- Elimina namespace `springboot-products`
- Elimina todos los recursos asociados (pods, services, etc.)

##### **Archivos temporales (`-TempFiles`):**
- `*.log`, `*.tmp`, `*.backup`
- Carpeta `target/` (Maven)
- Carpeta `node_modules/` (si existe)

#### **Cuándo usarlo:**
- 🔄 Resetear el entorno a estado inicial
- 🧹 Liberar espacio en disco
- 🐛 Resolver problemas de estado corrupto
- 🔄 Antes de reconstruir desde cero

#### **⚠️ ADVERTENCIA:**
- Perderás datos en base de datos (PersistentVolumes)
- Se eliminarán todos los contenedores y pods

---

### **list-scripts.ps1** - Inventario de scripts

Lista todos los scripts disponibles con descripciones y ejemplos.

```powershell
.\list-scripts.ps1
```

#### **Salida:**
```
📜 SCRIPTS DISPONIBLES DEL PROYECTO
===================================

🐳 Scripts de Docker
────────────────────
  📄 docker-manager.ps1 - Gestión completa de Docker
      Uso: .\docker\docker-manager.ps1

  📄 run-local.ps1 - Inicio rápido local
      Uso: .\docker\run-local.ps1

☸️ Scripts de Kubernetes
───────────────────────
  📄 deploy-local.ps1 - Desplegar en Docker Desktop
      Uso: .\kubernetes\deploy-local.ps1

  📄 deploy-aks.ps1 - Desplegar en Azure AKS
      Uso: .\kubernetes\deploy-aks.ps1

⭐ SCRIPTS MÁS UTILIZADOS
─────────────────────────
🐳 Gestión completa de Docker
   📝 .\docker\docker-manager.ps1 -Environment prod -Action build-run
...
```

#### **Cuándo usarlo:**
- 🤔 Olvidaste qué scripts hay disponibles
- 📚 Necesitas ejemplos de uso
- 🆕 Primera vez usando el proyecto

---

### **test-api-requests.ps1** - Testing de API

Prueba todos los endpoints de la API REST.

```powershell
# Servidor local (puerto 8080)
.\test-api-requests.ps1

# Servidor personalizado
.\test-api-requests.ps1 -BaseUrl "http://localhost:8080"

# Modo verbose (detallado)
.\test-api-requests.ps1 -Verbose
```

#### **Endpoints probados:**
1. ✅ **Health Check** - `/actuator/health`
2. ✅ **Listar productos** - `GET /api/v1/products`
3. ✅ **Crear producto** - `POST /api/v1/products`
4. ✅ **Obtener por ID** - `GET /api/v1/products/{id}`
5. ✅ **Actualizar** - `PUT /api/v1/products/{id}`
6. ✅ **Buscar** - `GET /api/v1/products/search?name=...`
7. ✅ **Eliminar** - `DELETE /api/v1/products/{id}`
8. ✅ **Validación** - Prueba datos inválidos

#### **Salida ejemplo:**
```
🧪 TEST DE ENDPOINTS DE LA API
===============================

1️⃣ Health Check
═══════════════
🔍 Verificar estado de la aplicación
   GET /actuator/health
   ✅ Success (125ms)

2️⃣ Listar Productos
═══════════════════
🔍 Obtener lista de todos los productos
   GET /api/v1/products
   ✅ Success (234ms)

3️⃣ Crear Producto
═════════════════
🔍 Crear nuevo producto
   POST /api/v1/products
   ✅ Success (189ms)
   📝 Producto creado con ID: 123

...

📊 RESUMEN DE PRUEBAS
════════════════════
Pruebas exitosas: 8
Pruebas fallidas: 0
Tiempo total: 1247ms

✅ Todos los endpoints funcionan correctamente
🎉 La API está lista para usar
```

#### **Cuándo usarlo:**
- ✅ Verificar que la API funciona después de desplegar
- ✅ Testing manual de endpoints
- ✅ Validar cambios en el backend
- ✅ Debugging de problemas de API

---

## 🎯 Flujos de trabajo recomendados

### **Primera vez con el proyecto**

```powershell
# 1. Configurar entorno
.\setup-environment.ps1

# 2. Desplegar aplicación
..\docker\run-local.ps1

# 3. Probar API
.\test-api-requests.ps1
```

### **Desarrollo diario**

```powershell
# Iniciar aplicación
..\docker\run-local.ps1

# Probar cambios
.\test-api-requests.ps1

# Ver logs si hay problemas
docker logs -f springboot-local
```

### **Resolver problemas**

```powershell
# 1. Diagnosticar
.\diagnose.ps1

# 2. Limpiar si es necesario
.\cleanup.ps1 -All

# 3. Reconstruir
..\docker\docker-manager.ps1 -Environment dev -Action build-run

# 4. Verificar
.\test-api-requests.ps1
```

### **Preparar para producción**

```powershell
# 1. Limpiar entorno
.\cleanup.ps1 -All

# 2. Build producción
..\docker\docker-manager.ps1 -Environment prod -Action build

# 3. Probar localmente
..\docker\docker-manager.ps1 -Environment prod -Action run
.\test-api-requests.ps1

# 4. Subir a ACR
..\kubernetes\build-and-push.ps1 -ACRName "miacr" -Tag "v1.0.0"

# 5. Desplegar en AKS
..\kubernetes\deploy-aks.ps1
```

---

## 📊 Comparativa de scripts

| Script | Cuándo usarlo | Nivel |
|--------|---------------|-------|
| `setup-environment.ps1` | Primera vez | Principiante |
| `list-scripts.ps1` | Para aprender | Principiante |
| `test-api-requests.ps1` | Testing diario | Intermedio |
| `diagnose.ps1` | Hay problemas | Intermedio |
| `cleanup.ps1` | Resetear entorno | Avanzado |

---

## 🐛 Troubleshooting común

### **"Script no reconocido"**

```powershell
# Solución: Navega al directorio correcto
cd scripts\utils
.\diagnose.ps1
```

### **"No se puede ejecutar porque está deshabilitado"**

```powershell
# Solución: Cambiar política de ejecución (admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **"Docker no está corriendo"**

```powershell
# Solución: Abrir Docker Desktop y esperar a que inicie
# Luego ejecutar:
.\diagnose.ps1
```

### **"No hay conexión con Kubernetes"**

```powershell
# Solución: Verificar contexto
kubectl config current-context

# Si no es docker-desktop:
kubectl config use-context docker-desktop
```

---

## 💡 Tips y mejores prácticas

1. ✅ **Ejecuta `setup-environment.ps1` la primera vez**
2. ✅ **Usa `diagnose.ps1` antes de reportar bugs**
3. ✅ **Ejecuta `test-api-requests.ps1` después de cambios**
4. ✅ **Limpia con `cleanup.ps1` si hay comportamiento extraño**
5. ✅ **Consulta `list-scripts.ps1` cuando olvides algo**
6. ⚠️ **NO ejecutes `cleanup.ps1 -All` en producción**
7. ⚠️ **Haz backup antes de `cleanup.ps1` con datos importantes**

---

## 🆘 Obtener ayuda

```powershell
# Ayuda detallada de un script
Get-Help .\diagnose.ps1 -Full

# Ver ejemplos
Get-Help .\cleanup.ps1 -Examples

# Listar todos los scripts
.\list-scripts.ps1

# Documentación completa
..\..\README.md
```

---

## 📚 Referencias

- [Scripts Docker](../docker/README.md)
- [Scripts Kubernetes](../kubernetes/README.md)
- [Documentación principal](../../README.md)
- [PowerShell Docs](https://docs.microsoft.com/powershell/)