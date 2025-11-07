package com.david.springboot.backend.backend_products;

import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.entities.User;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;
import com.david.springboot.backend.backend_products.repositories.UserRepository;

import org.junit.jupiter.api.*;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.junit.jupiter.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test avanzado de Testcontainers que demuestra:
 * 1. Configuración de red personalizada
 * 2. Inicialización de datos
 * 3. Tests de relaciones entre entidades
 * 4. Manejo de transacciones
 * 5. Configuración avanzada de MySQL
 */
@SpringBootTest
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AdvancedTestcontainersIT {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Red personalizada para contenedores
    static final Network network = Network.newNetwork();

    // Contenedor MySQL con configuración avanzada
    @Container
    static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("advanced_testdb")
            .withUsername("admin")
            .withPassword("secretpass123")
            .withStartupTimeout(Duration.ofMinutes(3))
            .withNetwork(network)
            .withNetworkAliases("mysql-server")
            // Configuración personalizada de MySQL
            .withCommand(
                    "--character-set-server=utf8mb4",
                    "--collation-server=utf8mb4_unicode_ci",
                    "--sql-mode=STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO",
                    "--innodb-buffer-pool-size=256M")
            // Variables de entorno adicionales
            .withEnv("MYSQL_ROOT_HOST", "%")
            .withEnv("TZ", "UTC");

    @DynamicPropertySource
    static void configureDatabaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");

        // Configuración JPA optimizada para tests
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.jpa.show-sql", () -> "false"); // Desactivar para logs más limpios
        registry.add("spring.jpa.properties.hibernate.format_sql", () -> "true");
        registry.add("spring.jpa.properties.hibernate.jdbc.batch_size", () -> "20");
        registry.add("spring.jpa.properties.hibernate.order_inserts", () -> "true");
        registry.add("spring.jpa.properties.hibernate.order_updates", () -> "true");

        // Configuración de conexión
        registry.add("spring.datasource.hikari.maximum-pool-size", () -> "5");
        registry.add("spring.datasource.hikari.minimum-idle", () -> "2");

        // Logging para debugging (solo si es necesario)
        registry.add("logging.level.org.testcontainers", () -> "INFO");
        registry.add("logging.level.com.github.dockerjava", () -> "WARN");
    }

    @BeforeAll
    static void printTestInfo() {
        System.out.println("🚀 === TEST AVANZADO DE TESTCONTAINERS ===");
        System.out.println("📦 Imagen MySQL: " + mysql.getDockerImageName());
        System.out.println("🔗 Red Docker: " + network.getId().substring(0, 12) + "...");
        System.out.println("💾 Base de datos: " + mysql.getDatabaseName());
        System.out.println("👤 Usuario: " + mysql.getUsername());
        System.out.println("🌐 JDBC URL: " + mysql.getJdbcUrl());
        System.out.println("⏱️ Timeout configurado: 3 minutos");
        System.out.println("=====================================");
    }

    @AfterAll
    static void cleanup() {
        System.out.println("🧹 Limpiando recursos de Testcontainers...");
        // La red se limpia automáticamente
    }

    private static boolean dataInitialized = false;

    @BeforeEach
    void initializeTestData() {
        if (!dataInitialized) {
            System.out.println("📝 Inicializando datos de prueba...");

            // Crear usuarios de prueba
            createTestUsers();

            // Crear productos de prueba
            createTestProducts();

            dataInitialized = true;
            System.out.println("✅ Datos de prueba inicializados");
        }
    }

    private void createTestUsers() {
        User admin = new User();
        admin.setUsername("admin");
        admin.setEmail("admin@test.com");
        admin.setPassword(passwordEncoder.encode("admin123"));

        User user = new User();
        user.setUsername("testuser");
        user.setEmail("user@test.com");
        user.setPassword(passwordEncoder.encode("user123"));

        userRepository.saveAll(List.of(admin, user));
        System.out.println("👥 Usuarios creados: " + userRepository.count());
    }

    private void createTestProducts() {
        Product laptop = new Product();
        laptop.setName("Laptop Gaming");
        laptop.setDescription("Laptop para juegos de alta gama");
        laptop.setPrice(1500L);
        laptop.setQuantity(10L);

        Product mouse = new Product();
        mouse.setName("Mouse Inalámbrico");
        mouse.setDescription("Mouse ergonómico inalámbrico");
        mouse.setPrice(50L);
        mouse.setQuantity(100L);

        Product keyboard = new Product();
        keyboard.setName("Teclado Mecánico");
        keyboard.setDescription("Teclado mecánico RGB");
        keyboard.setPrice(120L);
        keyboard.setQuantity(50L);

        productRepository.saveAll(List.of(laptop, mouse, keyboard));
        System.out.println("📦 Productos creados: " + productRepository.count());
    }

    @Test
    @Order(1)
    @DisplayName("🔍 Verificar configuración inicial de la base de datos")
    void shouldVerifyInitialDatabaseSetup() {
        System.out.println("🔍 Test: Verificando configuración inicial...");

        // Verificar que los datos se han cargado correctamente
        long userCount = userRepository.count();
        long productCount = productRepository.count();

        assertAll(
                () -> assertEquals(2L, userCount, "Deben existir 2 usuarios"),
                () -> assertEquals(3L, productCount, "Deben existir 3 productos"),
                () -> assertTrue(mysql.isRunning(), "El contenedor MySQL debe estar ejecutándose"),
                () -> assertNotNull(mysql.getJdbcUrl(), "La URL JDBC no debe ser null"));

        System.out.println("✅ Configuración inicial verificada");
        System.out.println("   - Usuarios: " + userCount);
        System.out.println("   - Productos: " + productCount);
        System.out.println("   - Contenedor activo: " + mysql.isRunning());
    }

    @Test
    @Order(2)
    @DisplayName("📊 Probar consultas complejas de productos")
    @Transactional
    void shouldExecuteComplexProductQueries() {
        System.out.println("📊 Test: Ejecutando consultas complejas...");

        // Consultar productos por rango de precio
        List<Product> expensiveProducts = productRepository.findByPriceGreaterThan(100L);
        List<Product> cheapProducts = productRepository.findByPriceLessThan(100L);

        // Consultar por cantidad disponible
        List<Product> lowStockProducts = productRepository.findByQuantityLessThan(20L);
        List<Product> highStockProducts = productRepository.findByQuantityGreaterThan(20L);

        assertAll(
                () -> assertEquals(2, expensiveProducts.size(), "Deben haber 2 productos caros"),
                () -> assertEquals(1, cheapProducts.size(), "Debe haber 1 producto barato"),
                () -> assertEquals(1, lowStockProducts.size(), "Debe haber 1 producto con poco stock"),
                () -> assertEquals(2, highStockProducts.size(), "Deben haber 2 productos con mucho stock"));

        System.out.println("✅ Consultas complejas ejecutadas correctamente");
        System.out.println("   - Productos > $100: " + expensiveProducts.size());
        System.out.println("   - Productos < $100: " + cheapProducts.size());
        System.out.println("   - Stock bajo (<20): " + lowStockProducts.size());
        System.out.println("   - Stock alto (>20): " + highStockProducts.size());
    }

    @Test
    @Order(3)
    @DisplayName("🔐 Probar autenticación y usuarios")
    @Transactional
    void shouldTestUserAuthentication() {
        System.out.println("🔐 Test: Probando autenticación de usuarios...");

        // Buscar usuarios por username
        var adminUser = userRepository.findByUsername("admin");
        var testUser = userRepository.findByUsername("testuser");
        var nonExistentUser = userRepository.findByUsername("hacker");

        assertAll(
                () -> assertTrue(adminUser.isPresent(), "El usuario admin debe existir"),
                () -> assertTrue(testUser.isPresent(), "El usuario testuser debe existir"),
                () -> assertFalse(nonExistentUser.isPresent(), "El usuario hacker NO debe existir"),
                () -> assertEquals("admin@test.com", adminUser.get().getEmail(), "Email del admin correcto"),
                () -> assertEquals("user@test.com", testUser.get().getEmail(), "Email del testuser correcto"));

        // Verificar que las contraseñas están encriptadas
        assertTrue(adminUser.get().getPassword().startsWith("$2a$"),
                "La contraseña del admin debe estar encriptada con BCrypt");
        assertTrue(testUser.get().getPassword().startsWith("$2a$"),
                "La contraseña del testuser debe estar encriptada con BCrypt");

        System.out.println("✅ Autenticación de usuarios verificada");
        System.out.println("   - Admin encontrado: " + adminUser.isPresent());
        System.out.println("   - TestUser encontrado: " + testUser.isPresent());
        System.out.println("   - Contraseñas encriptadas: ✅");
    }

    @Test
    @Order(4)
    @DisplayName("⚡ Probar rendimiento de operaciones masivas")
    @Transactional
    void shouldTestBulkOperations() {
        System.out.println("⚡ Test: Probando operaciones masivas...");

        long startTime = System.currentTimeMillis();

        // Crear múltiples productos
        for (int i = 1; i <= 50; i++) {
            Product product = new Product();
            product.setName("Producto Masivo " + i);
            product.setDescription("Descripción del producto " + i);
            product.setPrice((long) (Math.random() * 1000 + 10));
            product.setQuantity((long) (Math.random() * 100 + 1));
            productRepository.save(product);
        }

        long insertTime = System.currentTimeMillis() - startTime;

        // Verificar que se crearon correctamente
        long totalProducts = productRepository.count();

        startTime = System.currentTimeMillis();
        List<Product> allProducts = productRepository.findAll();
        long queryTime = System.currentTimeMillis() - startTime;

        assertAll(
                () -> assertEquals(53L, totalProducts, "Deben existir 53 productos (3 iniciales + 50 nuevos)"),
                () -> assertEquals(53, allProducts.size(), "La consulta debe devolver todos los productos"),
                () -> assertTrue(insertTime < 5000, "Las inserciones deben tomar menos de 5 segundos"),
                () -> assertTrue(queryTime < 1000, "La consulta debe tomar menos de 1 segundo"));

        System.out.println("✅ Operaciones masivas completadas");
        System.out.println("   - Total productos: " + totalProducts);
        System.out.println("   - Tiempo inserción: " + insertTime + "ms");
        System.out.println("   - Tiempo consulta: " + queryTime + "ms");
    }
}