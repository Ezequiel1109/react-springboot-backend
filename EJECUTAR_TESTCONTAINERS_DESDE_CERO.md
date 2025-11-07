# 🚀 TESTCONTAINERS: EJECUCIÓN DESDE CERO

## 📋 PRERREQUISITOS (¡IMPORTANTE!)

### 1. **Docker debe estar ejecutándose**

```cmd
# Verificar Docker
docker --version
docker ps

# Si no funciona:
# 1. Buscar "Docker Desktop" en Windows
# 2. Hacer clic en "Docker Desktop"
# 3. Esperar a que aparezca el ícono verde en la bandeja
```

### 2. **Java 21 debe estar disponible**

```cmd
java --version
# Debe mostrar: Java 21 o superior
```

## 🎯 MÉTODO 1: EJECUCIÓN DIRECTA CON SCRIPT

### **Paso 1: Ejecutar el script automático**

```cmd
# Doble clic en este archivo:
run-testcontainers.bat

# O desde línea de comandos:
cd "C:\Users\Ivette Arias\Desktop\David Robinet\react-springboot-backend"
run-testcontainers.bat
```

### **Lo que verás:**

```
======================================
  TESTCONTAINERS - EJECUTANDO TESTS
======================================
Docker OK - Ejecutando tests...

[INFO] Scanning for projects...
[INFO]
[INFO] --- maven-surefire-plugin:3.5.4:test (default-test) @ backend-products ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO]
[INFO] Running com.david.springboot.backend.backend_products.SimpleTestcontainersIT
🐳 Iniciando contenedor MySQL: mysql:8.0
📊 Estado del contenedor: ✅ Ejecutándose
🔗 JDBC URL: jdbc:mysql://localhost:32768/simple_testdb
🧹 Base de datos limpiada para el test
✅ Usuario guardado con ID: 1
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO]
[INFO] Results:
[INFO]
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
```

## 🎯 MÉTODO 2: PASO A PASO MANUAL

### **Paso 1: Navegar al directorio**

```cmd
cd "C:\Users\Ivette Arias\Desktop\David Robinet\react-springboot-backend"
```

### **Paso 2: Ejecutar test específico**

```cmd
# Test más simple
.\mvnw.cmd test -Dtest=SimpleTestcontainersIT

# Test de repositorio
.\mvnw.cmd test -Dtest=UserRepositoryTestcontainersIT

# Test de integración completo
.\mvnw.cmd test -Dtest=ProductControllerMySqlIT

# Todos los tests de integración
.\mvnw.cmd test -Dtest="*IT"
```

## 🎯 MÉTODO 3: USANDO DOCKER DIRECTAMENTE

### **Si mvnw.cmd no funciona (problema de espacios):**

```cmd
# Ejecutar Maven en contenedor Docker
docker run --rm \
  -v "%CD%:/app" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -w /app \
  maven:3.9.5-eclipse-temurin-21 \
  mvn test -Dtest=SimpleTestcontainersIT
```

## 🎯 MÉTODO 4: IDE (MÁS RECOMENDADO)

### **Con IntelliJ IDEA:**

1. Abrir IntelliJ IDEA
2. Abrir el proyecto: `File > Open > Seleccionar carpeta`
3. Esperar a que cargue el proyecto
4. Navegar a: `src/test/java/.../SimpleTestcontainersIT.java`
5. Clic derecho → `Run 'SimpleTestcontainersIT'`

### **Con VS Code:**

1. Abrir VS Code
2. `File > Open Folder > Seleccionar carpeta`
3. Instalar extensión "Test Runner for Java"
4. Navegar a `SimpleTestcontainersIT.java`
5. Clic en el botón "Run Test" que aparece sobre cada método

### **Con Eclipse:**

1. Abrir Eclipse
2. `File > Import > Existing Maven Projects`
3. Seleccionar la carpeta del proyecto
4. Navegar a `SimpleTestcontainersIT.java`
5. Clic derecho → `Run As > JUnit Test`

## 🐳 QUÉ HACE TESTCONTAINERS AUTOMÁTICAMENTE

### **Fase 1: Preparación (30-60 segundos)**

```
🔍 Verificando imagen MySQL:8.0 localmente...
⬇️ Descargando imagen (solo primera vez)...
🐳 Creando contenedor MySQL...
⚙️ Configurando base de datos 'simple_testdb'...
👤 Creando usuario 'testuser'...
🔗 Esperando conexión MySQL...
```

### **Fase 2: Configuración de Spring (10-20 segundos)**

```
🔧 Configurando Spring Boot...
📊 Aplicando: spring.datasource.url=jdbc:mysql://localhost:32768/simple_testdb
🔑 Aplicando: spring.datasource.username=testuser
🔐 Aplicando: spring.datasource.password=testpass
🏗️ Creando tablas (hibernate.ddl-auto=create-drop)...
```

### **Fase 3: Ejecución de Tests (5-10 segundos)**

```
🧪 Ejecutando: shouldSaveAndRetrieveUser()...
✅ Test 1/4 pasado
🧪 Ejecutando: shouldFindUserByUsername()...
✅ Test 2/4 pasado
🧪 Ejecutando: shouldEnforceUniqueUsername()...
✅ Test 3/4 pasado
🧪 Ejecutando: shouldHandleMultipleUsers()...
✅ Test 4/4 pasado
```

### **Fase 4: Limpieza (5 segundos)**

```
🧹 Deteniendo contenedor MySQL...
🗑️ Eliminando contenedor...
🔗 Limpiando red Docker...
✅ Limpieza completada
```

## 🔍 MONITOREO EN TIEMPO REAL

### **Ver contenedores Docker mientras se ejecutan:**

```cmd
# En otra terminal (mientras corren los tests):
docker ps

# Verás algo como:
CONTAINER ID   IMAGE       COMMAND                  CREATED          STATUS          PORTS                    NAMES
a1b2c3d4e5f6   mysql:8.0   "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds    0.0.0.0:32768->3306/tcp  gracious_tesla
```

### **Ver logs del contenedor MySQL:**

```cmd
# Reemplaza CONTAINER_ID con el ID real
docker logs a1b2c3d4e5f6
```

## 🐛 SOLUCIÓN DE PROBLEMAS

### **Error: Docker no disponible**

```
SOLUCIÓN:
1. Abrir Docker Desktop
2. Esperar ícono verde en bandeja del sistema
3. Ejecutar: docker ps (debe funcionar sin errores)
```

### **Error: Puerto ocupado**

```
SOLUCIÓN:
Testcontainers usa puertos aleatorios automáticamente.
No debería haber conflictos.
```

### **Error: mvnw.cmd no funciona**

```
CAUSA: Espacios en ruta "Ivette Arias"
SOLUCIÓN 1: Usar IDE (IntelliJ/VS Code/Eclipse)
SOLUCIÓN 2: Mover proyecto a C:\dev\
SOLUCIÓN 3: Usar Docker con Maven
```

### **Error: Tests muy lentos**

```
PRIMERA EJECUCIÓN: 2-3 minutos (descarga MySQL)
SIGUIENTES: 30-60 segundos
ESTO ES NORMAL
```

## 🎉 SEÑALES DE ÉXITO

### **Si todo funciona correctamente verás:**

✅ Mensaje: "Tests run: X, Failures: 0, Errors: 0"
✅ Logs: "🐳 Iniciando contenedor MySQL"
✅ Logs: "✅ Usuario guardado con ID: X"
✅ Logs: "🧹 Limpiando recursos"
✅ El proceso termina sin errores

## 🚀 PRÓXIMO PASO

**EJECUTA AHORA:**

```cmd
# Método más simple:
run-testcontainers.bat

# O con IDE:
Abrir IntelliJ → SimpleTestcontainersIT.java → Run Test
```

¡Si ves los logs de MySQL descargándose y los tests pasando, Testcontainers está funcionando perfectamente! 🎉
