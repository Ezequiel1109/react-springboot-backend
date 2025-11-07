package com.david.springboot.backend.backend_products;

import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.entities.User;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;
import com.david.springboot.backend.backend_products.repositories.UserRepository;

import org.junit.jupiter.api.*;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test simple de Testcontainers que demuestra el uso básico
 * Compatible con los repositorios existentes
 */
@SpringBootTest
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class SimpleTestcontainersIT {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Contenedor MySQL básico
    @Container
    static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("simple_testdb")
            .withUsername("testuser")
            .withPassword("testpass")
            .withStartupTimeout(Duration.ofMinutes(2));

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.jpa.show-sql", () -> "true");
    }

    @BeforeAll
    static void printInfo() {
        System.out.println("🐳 === TESTCONTAINERS SIMPLE ===");
        System.out.println("📦 MySQL: " + mysql.getDatabaseName());
        System.out.println("🔗 URL: " + mysql.getJdbcUrl());
        System.out.println("============================");
    }

    @BeforeEach
    void cleanDatabase() {
        productRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    @Order(1)
    @DisplayName("✅ Verificar que el contenedor MySQL funciona")
    void shouldVerifyMySQLContainer() {
        System.out.println("✅ Test: Verificando contenedor MySQL...");

        assertTrue(mysql.isRunning(), "MySQL debe estar ejecutándose");
        assertNotNull(mysql.getJdbcUrl(), "JDBC URL no debe ser null");
        assertTrue(mysql.getJdbcUrl().contains("testdb"), "URL debe contener el nombre de la BD");

        System.out.println("   ✅ Contenedor verificado correctamente");
    }

    @Test
    @Order(2)
    @DisplayName("👤 Crear y buscar usuarios")
    @Transactional
    void shouldCreateAndFindUsers() {
        System.out.println("👤 Test: Creando usuarios...");

        // Crear usuarios
        User user1 = new User();
        user1.setUsername("testuser1");
        user1.setEmail("user1@test.com");
        user1.setPassword(passwordEncoder.encode("password123"));

        User user2 = new User();
        user2.setUsername("testuser2");
        user2.setEmail("user2@test.com");
        user2.setPassword(passwordEncoder.encode("password456"));

        // Guardar usuarios
        User savedUser1 = userRepository.save(user1);
        User savedUser2 = userRepository.save(user2);

        // Verificar que se guardaron
        assertAll(
                () -> assertNotNull(savedUser1.getId()),
                () -> assertNotNull(savedUser2.getId()),
                () -> assertEquals(2, userRepository.count()));

        // Buscar por email (método disponible en UserRepository)
        Optional<User> foundUser = userRepository.findByEmail("user1@test.com");
        assertTrue(foundUser.isPresent());
        assertEquals("testuser1", foundUser.get().getUsername());

        System.out.println("   ✅ Usuarios creados y encontrados: " + userRepository.count());
    }

    @Test
    @Order(3)
    @DisplayName("📦 Crear y consultar productos")
    @Transactional
    void shouldCreateAndQueryProducts() {
        System.out.println("📦 Test: Creando productos...");

        // Crear productos
        Product laptop = new Product();
        laptop.setName("Laptop Test");
        laptop.setDescription("Laptop para testing");
        laptop.setPrice(1000L);
        laptop.setQuantity(5L);

        Product mouse = new Product();
        mouse.setName("Mouse Test");
        mouse.setDescription("Mouse para testing");
        mouse.setPrice(25L);
        mouse.setQuantity(50L);

        // Guardar productos
        Product savedLaptop = productRepository.save(laptop);
        Product savedMouse = productRepository.save(mouse);

        // Verificar que se guardaron
        assertAll(
                () -> assertNotNull(savedLaptop.getId()),
                () -> assertNotNull(savedMouse.getId()),
                () -> assertEquals(2, productRepository.count()));

        // Probar búsqueda por nombre (método disponible en ProductRepository)
        var foundProducts = productRepository.findByNameContainingIgnoreCase("test", null);
        assertEquals(2, foundProducts.getTotalElements());

        System.out.println("   ✅ Productos creados: " + productRepository.count());
    }

    @Test
    @Order(4)
    @DisplayName("🔄 Probar transacciones y rollback")
    @Transactional
    void shouldTestTransactions() {
        System.out.println("🔄 Test: Probando transacciones...");

        // Crear algunos datos
        User user = new User();
        user.setUsername("transactionuser");
        user.setEmail("trans@test.com");
        user.setPassword(passwordEncoder.encode("pass"));
        userRepository.save(user);

        Product product = new Product();
        product.setName("Transaction Product");
        product.setDescription("Para probar transacciones");
        product.setPrice(100L);
        product.setQuantity(10L);
        productRepository.save(product);

        // Verificar que existen
        assertEquals(1, userRepository.count());
        assertEquals(1, productRepository.count());

        System.out.println("   ✅ Datos creados en transacción");
        System.out.println("   📊 Usuarios: " + userRepository.count());
        System.out.println("   📊 Productos: " + productRepository.count());

        // Al final del test, @Transactional hace rollback automático
    }

    @Test
    @Order(5)
    @DisplayName("🧹 Verificar limpieza entre tests")
    void shouldVerifyCleanupBetweenTests() {
        System.out.println("🧹 Test: Verificando limpieza...");

        // Después del test anterior, los datos deben haber sido limpiados
        // por @Transactional y @BeforeEach
        assertEquals(0, userRepository.count(), "No deben quedar usuarios");
        assertEquals(0, productRepository.count(), "No deben quedar productos");

        System.out.println("   ✅ Base de datos limpia entre tests");
    }

    @Test
    @Order(6)
    @DisplayName("⚡ Probar rendimiento básico")
    void shouldTestBasicPerformance() {
        System.out.println("⚡ Test: Probando rendimiento básico...");

        long startTime = System.currentTimeMillis();

        // Crear 10 productos
        for (int i = 1; i <= 10; i++) {
            Product product = new Product();
            product.setName("Producto " + i);
            product.setDescription("Descripción " + i);
            product.setPrice((long) i * 10);
            product.setQuantity((long) i * 5);
            productRepository.save(product);
        }

        long createTime = System.currentTimeMillis() - startTime;

        startTime = System.currentTimeMillis();
        List<Product> allProducts = productRepository.findAll();
        long queryTime = System.currentTimeMillis() - startTime;

        assertAll(
                () -> assertEquals(10, productRepository.count()),
                () -> assertEquals(10, allProducts.size()),
                () -> assertTrue(createTime < 2000, "Creación debe ser rápida"),
                () -> assertTrue(queryTime < 500, "Consulta debe ser rápida"));

        System.out.println("   ⏱️ Tiempo creación: " + createTime + "ms");
        System.out.println("   ⏱️ Tiempo consulta: " + queryTime + "ms");
        System.out.println("   ✅ Rendimiento aceptable");
    }
}