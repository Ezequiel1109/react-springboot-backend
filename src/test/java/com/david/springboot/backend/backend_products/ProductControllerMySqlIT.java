package com.david.springboot.backend.backend_products;

import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;
import com.david.springboot.backend.backend_products.services.UserService;
import com.david.springboot.backend.backend_products.SecurityConfig.JwtAuthFilter;

import java.time.Duration;
import java.util.List;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;

import org.junit.jupiter.api.*;
import org.mockito.InjectMocks;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class ProductControllerMySqlIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProductRepository proRepository;

    @InjectMocks
    private UserService userService;

    @MockitoBean
    private JwtAuthFilter jwtAuthFilter;

    // Definir el contenedor de MySQL para las pruebas
    @Container
    static final MySQLContainer<?> mysqlContainer = new MySQLContainer<>("mysql:8.0.26")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test")
            .withStartupTimeout(Duration.ofMinutes(2));

    @DynamicPropertySource
    static void setDatasourceProperties(DynamicPropertyRegistry registry) {
        // Configurar las propiedades de la base de datos para que apunten al contenedor
        // de MySQL
        registry.add("spring.datasource.url", mysqlContainer::getJdbcUrl);
        registry.add("spring.datasource.username", mysqlContainer::getUsername);
        registry.add("spring.datasource.password", mysqlContainer::getPassword);
        registry.add("spring.datasource.driver-class-name", mysqlContainer::getDriverClassName);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "update");
    }

    @BeforeAll
    static void requireDocker() {
        assumeTrue(DockerClientFactory.instance().isDockerAvailable(),
                "Docker no está disponible, se omiten las pruebas de integración con MySQL.");
    }

    @BeforeEach
    void setUp() throws Exception {
        // configuracion del filtro JWT mockeado, para ver si la peticion trae un
        // "Authorization: Bearer"
        doAnswer(invocation -> {
            ServletRequest req = invocation.getArgument(0);
            ServletResponse res = invocation.getArgument(1);
            FilterChain chain = invocation.getArgument(2);

            if (req instanceof HttpServletRequest) {
                HttpServletRequest httpReq = (HttpServletRequest) req;
                String authHeader = httpReq.getHeader("Authorization");
                if (authHeader != null && !authHeader.isBlank()) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            "testuser", null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
            // continua con la cadena de filtros/servlet
            try {
                chain.doFilter(req, res);
            } catch (ServletException | IOException e) {
                throw new RuntimeException(e);
            }
            return null;
        }).when(jwtAuthFilter).doFilter(any(ServletRequest.class), any(ServletResponse.class), any(FilterChain.class));

        proRepository.deleteAll();
        // Datos de prueba
        Product product1 = new Product();
        product1.setName("Product 1");
        product1.setPrice(100L);
        product1.setQuantity(230L);
        product1.setDescription("Description 1");

        Product product2 = new Product();
        product2.setName("Product 2");
        product2.setPrice(200L);
        product2.setQuantity(150L);
        product2.setDescription("Description 2");

        proRepository.saveAll(List.of(product1, product2));

    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void findAll_returnsSavedProducts() throws Exception {
        mockMvc.perform(get("/api/products")
                .header("Authorization", "Bearer faketoken")
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.content", hasSize(2)))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content[0].name").value("Product 1"))
                .andExpect(jsonPath("$.content[0].price").value(100))
                .andExpect(jsonPath("$.content[0].quantity").value(230))
                .andExpect(jsonPath("$.content[0].description").value("Description 1"))
                .andExpect(jsonPath("$.content[1].name").value("Product 2"))
                .andExpect(jsonPath("$.content[1].price").value(200))
                .andExpect(jsonPath("$.content[1].quantity").value(150))
                .andExpect(jsonPath("$.content[1].description").value("Description 2"));
    }

}
