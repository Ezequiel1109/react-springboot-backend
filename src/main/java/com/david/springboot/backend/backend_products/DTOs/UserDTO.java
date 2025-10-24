package com.david.springboot.backend.backend_products.DTOs;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Data Transfer Object para registrar un usuario", example = "{ \"username\": \"johndoe\", \"email\": \"johndoe@example.com\", \"password\": \"password123\" }")

public class UserDTO {
    @NotBlank(message = "El nombre de usuario es obligatorio")
    @Size(max = 50, message = "El nombre de usuario no puede superar los 50 caracteres")
    @Schema(description = "Nombre de usuario del usuario", example = "johndoe", maxLength = 50, required = true)
    private String username;

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "El email debe tener un formato válido")
    @Size(max = 100, message = "El email no puede superar los 100 caracteres")
    @Schema(description = "Email del usuario", example = "johndoe@example.com", maxLength = 100, required = true)
    private String email;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, max = 100, message = "La contraseña debe tener entre 8 y 100 caracteres")
    @Schema(description = "Contraseña del usuario", example = "password123", minLength = 8, maxLength = 100, required = true)
    private String password;

    public UserDTO() {
    }

    public UserDTO(String username, String email, String password) {
        this.username = username;
        this.email = email;
        this.password = password;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
