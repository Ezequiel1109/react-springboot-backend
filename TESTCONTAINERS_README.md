# 🐳 GUÍA COMPLETA DE TESTCONTAINERS

## 📋 ¿Qué son los Testcontainers?

**Testcontainers** es una biblioteca de Java que permite ejecutar tests de integración usando contenedores Docker reales. En lugar de usar bases de datos en memoria (como H2), puedes usar MySQL, PostgreSQL, Redis, etc., en contenedores Docker que se crean y destruyen automáticamente.

## ✅ Ventajas de Testcontainers

- **🎯 Realismo**: Tests con la misma BD que producción
- **🧹 Limpieza**: Cada test tiene un contenedor fresco
- **🚀 Automático**: Se inician/detienen automáticamente
- **🔧 Fácil configuración**: Mínima configuración requerida
- **📦 Aislamiento**: Tests no se interfieren entre sí

## 📁 Archivos creados en tu proyecto:

### 1. **Tests de ejemplo:**

- ✅ `ProductControllerMySqlIT.java` (ya existía - corregido)
- ✅ `UserRepositoryTestcontainersIT.java` (nuevo - test de repositorio)
- ✅ `SimpleTestcontainersIT.java` (nuevo - ejemplos básicos)
- ⚠️ `AdvancedTestcontainersIT.java` (avanzado - tiene errores de compilación)

### 2. **Scripts de ejecución:**

- ✅ `run-testcontainers.ps1` (script avanzado)
- ✅ `run-tests-simple.ps1` (script básico)
- ✅ `TESTCONTAINERS_GUIDE.ps1` (esta guía)

### 3. **Configuración Docker:**

- ✅ `Dockerfile.test` (para ejecutar tests en Docker)
- ✅ `docker-compose.test.yml` (para tests complejos)
- ✅ `src/test/resources/application-test.properties` (configuración de test)

## 🚀 CÓMO EJECUTAR LOS TESTS

### **Opción 1: IDE (MÁS RECOMENDADO)**

```
1. Abre IntelliJ IDEA, Eclipse, o VS Code
2. Inicia Docker Desktop
3. Haz clic derecho en cualquier test *IT.java
4. Selecciona "Run Test"
5. ¡Listo! Testcontainers hará todo automáticamente
```

### **Opción 2: Mover proyecto (SOLUCIONARÁ PROBLEMA DE MVNW)**

El problema actual es que la ruta tiene espacios: "Ivette Arias"

```powershell
# Crear directorio sin espacios
mkdir C:\dev
# Mover el proyecto
xcopy "C:\Users\Ivette Arias\Desktop\David Robinet\react-springboot-backend" "C:\dev\react-springboot-backend" /E /I
# Cambiar al nuevo directorio
cd C:\dev\react-springboot-backend
# Ejecutar tests
.\mvnw.cmd test
```

### **Opción 3: Docker con Maven**

```powershell
# Asegúrate de que Docker Desktop está ejecutándose
docker run --rm -v "${PWD}:/app" -v "/var/run/docker.sock:/var/run/docker.sock" -w /app maven:3.9.5-eclipse-temurin-21 mvn test
```

### **Opción 4: Instalar Maven globalmente**

```powershell
# Descargar de: https://maven.apache.org/download.cgi
# Configurar PATH
# Luego ejecutar:
mvn test
```

## 🔧 CONFIGURACIÓN ACTUAL

### **En pom.xml (YA CONFIGURADO):**

```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>mysql</artifactId>
    <version>1.19.0</version>
    <scope>test</scope>
</dependency>
```

### **En los tests (PATRÓN BÁSICO):**

```java
@SpringBootTest
@Testcontainers
class MiTestIT {

    @Container
    static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Test
    void miTest() {
        // Tu código de test aquí
        // MySQL se inicia automáticamente
    }
}
```

## 📊 QUÉ HACE TESTCONTAINERS AUTOMÁTICAMENTE

1. **🚀 Al iniciar el test:**

   - Descarga la imagen MySQL (solo la primera vez)
   - Crea y inicia un contenedor MySQL
   - Espera a que MySQL esté listo
   - Configura la conexión de Spring Boot

2. **✅ Durante el test:**

   - Tu aplicación se conecta a MySQL real
   - Puedes crear/leer/actualizar/eliminar datos
   - Cada test tiene datos limpios

3. **🧹 Al finalizar el test:**
   - Detiene y elimina el contenedor
   - Limpia todos los recursos
   - No quedan contenedores "huérfanos"

## 🐛 RESOLUCIÓN DE PROBLEMAS

### **Problema: Docker no funciona**

```powershell
# Verificar Docker
docker --version
docker ps

# Si no funciona, iniciar Docker Desktop
# En Windows: buscar "Docker Desktop" y ejecutar
```

### **Problema: mvnw.cmd falla por espacios en ruta**

```powershell
# Mover proyecto a ruta sin espacios
mkdir C:\dev
xcopy "ruta-con-espacios" "C:\dev\proyecto" /E /I
```

### **Problema: Tests muy lentos**

- La primera ejecución es lenta (descarga MySQL)
- Siguientes ejecuciones son más rápidas
- Usa `@Testcontainers` con contenedores `static` para reutilizar

### **Problema: Puerto ocupado**

Testcontainers usa puertos aleatorios, no debería haber conflictos.

## 🎯 EJEMPLOS ESPECÍFICOS

### **Test básico de repositorio:**

```java
@Test
void shouldSaveUser() {
    User user = new User();
    user.setUsername("test");
    user.setEmail("test@example.com");

    User saved = userRepository.save(user);

    assertNotNull(saved.getId());
}
```

### **Test de integración completo:**

```java
@Test
void shouldCreateUserAndProducts() {
    // Crear usuario
    User user = createTestUser();

    // Crear productos
    Product product = createTestProduct();

    // Verificar que se guardaron en MySQL
    assertEquals(1, userRepository.count());
    assertEquals(1, productRepository.count());
}
```

## 🏆 MEJORES PRÁCTICAS

1. **✅ Usar `@Testcontainers`** en la clase
2. **✅ Contenedores `static`** para reutilizar
3. **✅ `@DynamicPropertySource`** para configuración
4. **✅ Limpiar datos** en `@BeforeEach`
5. **✅ Tests independientes** (no dependen del orden)
6. **✅ Assertions específicas** y claras

## 📝 SIGUIENTE PASO

**RECOMENDACIÓN:** Mover el proyecto a `C:\dev\react-springboot-backend` para solucionar el problema con mvnw.cmd y luego ejecutar:

```powershell
cd C:\dev\react-springboot-backend
.\mvnw.cmd test -Dtest="SimpleTestcontainersIT"
```

¡Esto te permitirá ver Testcontainers en acción! 🎉
