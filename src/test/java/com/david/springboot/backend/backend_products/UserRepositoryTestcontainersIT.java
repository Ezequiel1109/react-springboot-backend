package com.david.springboot.backend.backend_products;

import com.david.springboot.backend.backend_products.entities.User;
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
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test de integración para UserRepository usando Testcontainers
 * Este test demuestra cómo usar Testcontainers para tests de repositorio
 */
@SpringBootTest
@Testcontainers
@Transactional
class UserRepositoryTestcontainersIT {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Contenedor MySQL compartido para todos los tests
    @Container
    static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass")
            .withStartupTimeout(Duration.ofMinutes(2))
            .withCommand("--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci");

    @DynamicPropertySource
    static void configureMySQLProperties(DynamicPropertyRegistry registry) {
        // Configuración dinámica de la base de datos
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");

        // Configuración JPA para tests
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.jpa.show-sql", () -> "true");
        registry.add("spring.jpa.properties.hibernate.format_sql", () -> "true");
    }

    @BeforeAll
    static void beforeAll() {
        System.out.println("🐳 Iniciando contenedor MySQL: " + mysql.getDockerImageName());
        System.out.println("📊 Estado del contenedor: " + (mysql.isRunning() ? "✅ Ejecutándose" : "❌ Detenido"));
        System.out.println("🔗 JDBC URL: " + mysql.getJdbcUrl());
    }

    @AfterAll
    static void afterAll() {
        System.out.println("🛑 Deteniendo contenedor MySQL...");
    }

    @BeforeEach
    void setUp() {
        // Limpiar datos antes de cada test
        userRepository.deleteAll();
        System.out.println("🧹 Base de datos limpiada para el test");
    }

    @Test
    @DisplayName("Debería guardar y recuperar un usuario correctamente")
    void shouldSaveAndRetrieveUser() {
        // Given
        User user = new User();
        user.setUsername("testuser");
        user.setEmail("test@example.com");
        user.setPassword(passwordEncoder.encode("password123"));

        // When
        User savedUser = userRepository.save(user);
        Optional<User> retrievedUser = userRepository.findById(savedUser.getId());

        // Then
        assertAll(
                () -> assertNotNull(savedUser.getId(), "El ID del usuario guardado no debe ser null"),
                () -> assertTrue(retrievedUser.isPresent(), "El usuario debe ser encontrado"),
                () -> assertEquals("testuser", retrievedUser.get().getUsername(), "El username debe coincidir"),
                () -> assertEquals("test@example.com", retrievedUser.get().getEmail(), "El email debe coincidir"),
                () -> assertNotEquals("password123", retrievedUser.get().getPassword(),
                        "La contraseña debe estar encriptada"));

        System.out.println("✅ Usuario guardado con ID: " + savedUser.getId());
    }

    @Test
    @DisplayName("Debería encontrar usuario por username")
    void shouldFindUserByUsername() {
        // Given
        User user = new User();
        user.setUsername("john_doe");
        user.setEmail("john@example.com");
        user.setPassword(passwordEncoder.encode("secret123"));
        userRepository.save(user);

        // When
        Optional<User> foundUser = userRepository.findByUsername("john_doe");

        // Then
        assertAll(
                () -> assertTrue(foundUser.isPresent(), "El usuario debe ser encontrado por username"),
                () -> assertEquals("john_doe", foundUser.get().getUsername(), "El username debe coincidir"),
                () -> assertEquals("john@example.com", foundUser.get().getEmail(), "El email debe coincidir"));

        System.out.println("✅ Usuario encontrado por username: " + foundUser.get().getUsername());
    }

    @Test
    @DisplayName("Debería verificar que el username es único")
    void shouldEnforceUniqueUsername() {
        // Given
        User user1 = new User();
        user1.setUsername("duplicate_user");
        user1.setEmail("user1@example.com");
        user1.setPassword(passwordEncoder.encode("password1"));
        userRepository.save(user1);

        User user2 = new User();
        user2.setUsername("duplicate_user"); // Mismo username
        user2.setEmail("user2@example.com");
        user2.setPassword(passwordEncoder.encode("password2"));

        // When & Then
        assertThrows(Exception.class, () -> {
            userRepository.save(user2);
            userRepository.flush(); // Forzar la sincronización con la BD
        }, "Debería lanzar excepción por username duplicado");

        System.out.println("✅ Restricción de username único funcionando correctamente");
    }

    @Test
    @DisplayName("Debería manejar múltiples usuarios")
    void shouldHandleMultipleUsers() {
        // Given
        User user1 = new User();
        user1.setUsername("user1");
        user1.setEmail("user1@example.com");
        user1.setPassword(passwordEncoder.encode("pass1"));

        User user2 = new User();
        user2.setUsername("user2");
        user2.setEmail("user2@example.com");
        user2.setPassword(passwordEncoder.encode("pass2"));

        User user3 = new User();
        user3.setUsername("user3");
        user3.setEmail("user3@example.com");
        user3.setPassword(passwordEncoder.encode("pass3"));

        // When
        userRepository.save(user1);
        userRepository.save(user2);
        userRepository.save(user3);

        long userCount = userRepository.count();

        // Then
        assertEquals(3L, userCount, "Deben existir exactamente 3 usuarios");

        System.out.println("✅ Se guardaron " + userCount + " usuarios correctamente");
    }
}