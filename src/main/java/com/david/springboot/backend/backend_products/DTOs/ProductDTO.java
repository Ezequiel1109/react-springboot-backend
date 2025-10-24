package com.david.springboot.backend.backend_products.DTOs;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Data Transfer Object para crear o actualizar un producto", example = "{ \"name\": \"Laptop\", \"price\": 999.99, \"quantity\": 10, \"description\": \"Laptop de alta gama\" }")

public class ProductDTO {
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100, message = "El nombre no puede superar los 100 caracteres")
    @Schema(description = "Nombre del producto", example = "Laptop", maxLength = 100, required = true)
    private String name;

    @NotNull(message = "El precio es obligatorio")
    @Positive(message = "El precio debe ser un valor positivo")
    @Min(value = 1, message = "El precio debe ser mayor que cero")
    @Schema(description = "Precio del producto", example = "999.99", required = true)
    private Long price;

    @NotNull(message = "La cantidad es obligatoria")
    @Min(value = 0, message = "La cantidad no puede ser negativa")
    @PositiveOrZero(message = "La cantidad debe ser cero o un valor positivo")
    @Schema(description = "Cantidad del producto", example = "10", required = true)
    private Long quantity;

    @NotBlank(message = "La descripción es obligatoria")
    @Size(max = 500, message = "La descripción no puede superar los 500 carateres")
    @Schema(description = "Descripción del producto", example = "Laptop de alta gama", maxLength = 500, required = true)
    private String description;

    public ProductDTO() {
    }

    public ProductDTO(
            String name,
            Long price,
            Long quantity,
            String description) {
        this.name = name;
        this.price = price;
        this.quantity = quantity;
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Long getPrice() {
        return price;
    }

    public void setPrice(Long price) {
        this.price = price;
    }

    public Long getQuantity() {
        return quantity;
    }

    public void setQuantity(Long quantity) {
        this.quantity = quantity;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

}
