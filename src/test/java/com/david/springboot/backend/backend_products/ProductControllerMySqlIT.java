package com.david.springboot.backend.backend_products;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.testcontainers.junit.jupiter.Testcontainers;

import com.david.springboot.backend.backend_products.repositories.ProductRepository;


@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class ProductControllerMySqlIT {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductRepository proRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void findAllProducts_ReturnsProductList() throws Exception {
        // Configurar datos de prueba
        List<Product> products = Arrays.asList(
                new Product(1L, "Producto 1", "Descripción 1", 10.0),
                new Product(2L, "Producto 2", "Descripción 2", 20.0)
        );
        when(proRepository.findAll()).thenReturn(products);

        // Realizar la solicitud GET
        mockMvc.perform(get("/products")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(products.size()))
                .andExpect(jsonPath("$[0].name").value("Producto 1"))
                .andExpect(jsonPath("$[1].name").value("Producto 2"));
    }
            }
            // otro tipo de error
            Map<String, String> error = new HashMap<>();
            error.put("message", "Error al registrar el usuario.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }}

}
