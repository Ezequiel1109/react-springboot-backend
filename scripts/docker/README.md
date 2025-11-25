# 🐳 Scripts de Docker

Scripts para gestionar builds y contenedores Docker del proyecto Spring Boot.

## 📋 Scripts disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`docker-manager.ps1`** | Script principal para gestionar todo el ciclo de vida | `.\docker-manager.ps1 -Environment <env> -Action <action>` |
| `build-local.ps1` | Build rápido para desarrollo local | `.\build-local.ps1` |
| `run-local.ps1` | Ejecutar aplicación localmente | `.\run-local.ps1` |
| `docker-compose.ps1` | Gestionar Docker Compose | `.\docker-compose.ps1 up` |
| `push-to-registry.ps1` | Subir imagen a Azure Container Registry | `.\push-to-registry.ps1` |

---

## 🚀 Guía de uso

### **docker-manager.ps1** (Recomendado)

Script principal que maneja todas las operaciones de Docker.

#### **Parámetros:**

- **`-Environment`**: `prod` | `dev` | `test`
- **`-Action`**: 
  - `build` - Solo construir imagen
  - `run` - Solo ejecutar contenedor
  - `push` - Solo subir a registry
  - `build-run` - Construir y ejecutar
  - `build-push` - Construir y subir
  - `stop` - Detener contenedor
  - `logs` - Ver logs
  - `clean` - Limpiar recursos

#### **Ejemplos:**

```powershell
# Desarrollo: construir y ejecutar
.\docker-manager.ps1 -Environment dev -Action build-run

# Producción: construir y subir a ACR
.\docker-manager.ps1 -Environment prod -Action build-push

# Tests: ejecutar tests en contenedor
.\docker-manager.ps1 -Environment test -Action build-run

# Ver logs en tiempo real
.\docker-manager.ps1 -Environment prod -Action logs

# Detener contenedor
.\docker-manager.ps1 -Environment dev -Action stop

# Limpiar todo (contenedor + imagen)
.\docker-manager.ps1 -Environment dev -Action clean
```

---

### **Scripts específicos**

#### **run-local.ps1** - Inicio rápido

Forma más rápida de ejecutar la aplicación localmente:

```powershell
.\run-local.ps1
```

Esto hace:
1. ✅ Build de la imagen
2. ✅ Detiene contenedor anterior
3. ✅ Ejecuta nuevo contenedor en puerto 8080
4. ✅ Configura conexión a MySQL local

#### **build-local.ps1** - Solo construir

Solo construye la imagen sin ejecutarla:

```powershell
.\build-local.ps1
```

#### **docker-compose.ps1** - Múltiples servicios

Gestiona múltiples servicios (backend + MySQL):

```powershell
# Iniciar todos los servicios
.\docker-compose.ps1 up

# Detener todos los servicios
.\docker-compose.ps1 down

# Ver logs
.\docker-compose.ps1 logs
```

#### **push-to-registry.ps1** - Subir a Azure

Sube la imagen a Azure Container Registry:

```powershell
.\push-to-registry.ps1 -Tag latest
```

---

## 🎯 Flujos de trabajo comunes

### **Desarrollo local**

```powershell
# Opción 1: Inicio rápido
.\run-local.ps1

# Opción 2: Con docker-manager
.\docker-manager.ps1 -Environment dev -Action build-run

# Ver logs
.\docker-manager.ps1 -Environment dev -Action logs

# Detener
.\docker-manager.ps1 -Environment dev -Action stop
```

### **Ejecutar tests**

```powershell
# Construir y ejecutar tests en Docker
.\docker-manager.ps1 -Environment test -Action build-run
```

### **Preparar para producción**

```powershell
# 1. Construir imagen de producción
.\docker-manager.ps1 -Environment prod -Action build

# 2. Probar localmente (opcional)
.\docker-manager.ps1 -Environment prod -Action run

# 3. Subir a Azure Container Registry
.\docker-manager.ps1 -Environment prod -Action push
```

### **Desarrollo con Docker Compose**

```powershell
# Iniciar backend + MySQL
.\docker-compose.ps1 up -d

# Ver logs de ambos servicios
.\docker-compose.ps1 logs -f

# Detener todo
.\docker-compose.ps1 down
```

---

## 📊 Comparativa de Dockerfiles

| Dockerfile | Propósito | Tamaño aprox. | Características |
|------------|-----------|---------------|-----------------|
| `Dockerfile` | **Producción** | ~350 MB | Multi-stage, JRE ligero, optimizado |
| `Dockerfile.dev` | Desarrollo | ~550 MB | JDK completo, DevTools, hot-reload |
| `Dockerfile.test` | Tests | ~550 MB | JDK completo, H2 in-memory |

---

## 🔧 Configuración

### **Variables de entorno importantes**

```powershell
# Desarrollo (automático en run-local.ps1)
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:mysql://host.docker.internal:3306/db_backend_crud

# Producción (configurar en Kubernetes)
SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=jdbc:mysql://mysql-service:3306/db_backend_crud
```

### **Puertos utilizados**

- **8080** - Producción y desarrollo
- **8081** - Tests
- **5005** - Debug remoto (solo dev)

### **Azure Container Registry**

Edita `docker-manager.ps1` línea 26:

```powershell
$Registry = "tu-registry.azurecr.io"  # Cambiar por tu ACR
```

---

## 🐛 Troubleshooting

### **Error: "Docker no está corriendo"**

```powershell
# Solución: Abre Docker Desktop y espera a que inicie
```

### **Error: "Dockerfile no encontrado"**

```powershell
# Solución: Ejecuta desde la raíz del proyecto
cd react-springboot-backend
.\scripts\docker\docker-manager.ps1 -Environment prod -Action build
```

### **Puerto 8080 ya en uso**

```powershell
# Ver qué proceso usa el puerto
netstat -ano | findstr :8080

# Detener contenedor conflictivo
docker stop $(docker ps -q -f publish=8080)
```

### **Error de conexión a MySQL**

```powershell
# Verificar que MySQL esté corriendo
docker ps | findstr mysql

# O usar Docker Compose
.\scripts\docker\docker-compose.ps1 up -d
```

---

## 📖 Comandos Docker útiles

```powershell
# Ver imágenes
docker images springboot-products

# Ver contenedores corriendo
docker ps

# Ver todos los contenedores (incluidos detenidos)
docker ps -a

# Ver logs de un contenedor
docker logs -f <container-name>

# Ejecutar comando dentro del contenedor
docker exec -it <container-name> bash

# Inspeccionar contenedor
docker inspect <container-name>

# Ver uso de recursos
docker stats

# Limpiar todo (¡CUIDADO!)
docker system prune -a
```

---

## 📚 Referencias

- [Dockerfile producción](../../Dockerfile)
- [Dockerfile desarrollo](../../Dockerfile.dev)
- [Dockerfile tests](../../Dockerfile.test)
- [Docker Compose](../../docker-compose.yml)
- [Documentación oficial Docker](https://docs.docker.com/)

---

## 💡 Tips y mejores prácticas

1. ✅ **Usa `docker-manager.ps1`** para operaciones comunes
2. ✅ **Usa `run-local.ps1`** para inicio rápido
3. ✅ **Usa Docker Compose** para desarrollo con MySQL
4. ✅ **Construye localmente antes de push** para detectar errores
5. ✅ **Usa tags semánticos** en producción (`v1.0.0`, `v1.0.1`)
6. ⚠️ **NO subas Dockerfile.test a producción**
7. ⚠️ **NO uses `:latest` en producción**, usa versiones específicas

---

## 🆘 Obtener ayuda

```powershell
# Ver ayuda detallada de un script
Get-Help .\docker-manager.ps1 -Full

# Listar todos los scripts disponibles
..\utils\list-scripts.ps1
```