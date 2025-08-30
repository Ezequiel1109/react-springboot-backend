package com.david.springboot.backend.backend_products.entities;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonSetter;
import jakarta.persistence.*;

@Entity
@Table(name="products")
@JsonIgnoreProperties(ignoreUnknown = true)
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Long price;
    private Long quantity;
    private String description;
    
    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    
    // Método especial para manejar name si viene como objeto
    @JsonSetter("name")
    public void setNameFromJson(Object nameValue) {
        if (nameValue == null) {
            this.name = null;
        } else if (nameValue instanceof String) {
            this.name = (String) nameValue;
        } else {
            // Si viene un objeto, convertir a string
            this.name = nameValue.toString();
        }
    }
    public Long getPrice() {
        return price;
    }
    public void setPrice(Long price) {
        this.price = price;
    }
    
    // Método especial para manejar price como String (desde formularios)
    @JsonSetter("price")
    public void setPriceFromJson(Object priceValue) {
        if (priceValue == null) {
            this.price = null;
        } else if (priceValue instanceof Number) {
            this.price = ((Number) priceValue).longValue();
        } else if (priceValue instanceof String) {
            try {
                this.price = Long.parseLong((String) priceValue);
            } catch (NumberFormatException e) {
                this.price = 0L; // valor por defecto
            }
        } else {
            // Si viene un objeto, intentar extraer el valor
            this.price = 0L;
        }
    }
    public Long getQuantity() {
        return quantity;
    }
    public void setQuantity(Long quantity) {
        this.quantity = quantity;
    }
    
    // Método especial para manejar quantity como String (desde formularios)
    @JsonSetter("quantity")
    public void setQuantityFromJson(Object quantityValue) {
        if (quantityValue == null) {
            this.quantity = null;
        } else if (quantityValue instanceof Number) {
            this.quantity = ((Number) quantityValue).longValue();
        } else if (quantityValue instanceof String) {
            try {
                this.quantity = Long.parseLong((String) quantityValue);
            } catch (NumberFormatException e) {
                this.quantity = 0L; // valor por defecto
            }
        } else {
            // Si viene un objeto, intentar extraer el valor
            this.quantity = 0L;
        }
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    
    // Método especial para manejar description si viene como objeto
    @JsonSetter("description")
    public void setDescriptionFromJson(Object descriptionValue) {
        if (descriptionValue == null) {
            this.description = null;
        } else if (descriptionValue instanceof String) {
            this.description = (String) descriptionValue;
        } else {
            // Si viene un objeto, convertir a string
            this.description = descriptionValue.toString();
        }
    }
    
   
    

}
