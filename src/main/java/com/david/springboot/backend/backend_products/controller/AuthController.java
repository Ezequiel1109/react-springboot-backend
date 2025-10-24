package com.david.springboot.backend.backend_products.controller;

import com.david.springboot.backend.backend_products.services.UserService;

import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.media.*;

import java.util.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import com.david.springboot.backend.backend_products.DTOs.UserDTO;
import com.david.springboot.backend.backend_products.SecurityConfig.JwtAuthFilter;
import com.david.springboot.backend.backend_products.entities.User;

@RestController
@CrossOrigin(origins = { "http://localhost:3000" })
@RequestMapping("/user")
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtAuthFilter jwtAuthFilter;

    // Endpoint for user registration
    @PostMapping("/register")
    @Operation(summary = "Registrar un nuevo usuario", description = "Registra un nuevo usuario con los datos proporcionados en el cuerpo de la solicitud.", responses = {
            @ApiResponse(responseCode = "200", description = "Usuario registrado exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = User.class))),
            @ApiResponse(responseCode = "409", description = "Conflicto: El email ya está en uso", content = @Content(mediaType = "application/json", schema = @Schema(implementation = UserDTO.class), examples = @ExampleObject(value = "{\"username\": \"juan\", \"email\": \"juan@email.com\", \"password\": \"123456\"}"))),
            @ApiResponse(responseCode = "409", description = "Conflicto: El email ya está en uso", content = @Content(mediaType = "application/json", examples = @ExampleObject(value = "{\"field\": \"email\", \"message\": \"El email ya está registrado.\"}"))),
            @ApiResponse(responseCode = "400", description = "Datos inválidos en la solicitud", content = @Content(mediaType = "application/json", schema = @Schema(implementation = UserDTO.class), examples = @ExampleObject(value = "{\"username\": \"juan\", \"email\": \"juan@email.com\", \"password\": \"123456\"}"))),
            @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json", schema = @Schema(implementation = UserDTO.class), examples = @ExampleObject(value = "{\"username\": \"juan\", \"email\": \"juan@email.com\", \"password\": \"123456\"}")))
    })
    public ResponseEntity<?> register(@Valid @RequestBody UserDTO userDTO, BindingResult result) {
        if (result.hasErrors()) {
            Map<String, String> err = new HashMap<>();
            result.getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
            return ResponseEntity.badRequest().body(err);
        }
        try {
            User userToCreate = new User();
            userToCreate.setUsername(userDTO.getUsername());
            userToCreate.setEmail(userDTO.getEmail());
            userToCreate.setPassword(userDTO.getPassword());
            User registeredUser = userService.register(userToCreate);
            return ResponseEntity.status(HttpStatus.CREATED).body(registeredUser);
        } catch (Exception e) {
            // validacion para el correo duplicado
            if (e.getCause() != null && e.getCause().getMessage().contains("Duplicate entry")
                    && e.getCause().getMessage().contains("users.email")) {
                Map<String, String> error = new HashMap<>();
                error.put("field", "email");
                error.put("message", "El email ya está registrado.");
                return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error interno en el servidor: " + e.getMessage());
        }
    }

    // Endpoint for user login
    @PostMapping("/login")
    @Operation(summary = "Iniciar sesión de usuario", description = "Autentica a un usuario con las credenciales proporcionadas en el cuerpo de la solicitud y devuelve un token JWT si la autenticación es exitosa.", responses = {
            @ApiResponse(responseCode = "200", description = "Inicio de sesión exitoso", content = @Content(
                    mediaType = "application/json",
                    examples = @ExampleObject(value = "{\"token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\", \"expiresIn\": 3600}")
                )),
            @ApiResponse(responseCode = "400", description = "Datos inválidos en la solicitud", content = @Content(mediaType = "application/json", examples = @ExampleObject(value = "{\"email\": \"correo@ejemplo.com\", \"password\": \"contraseña\"}"))),
            @ApiResponse(responseCode = "401", description = "No autorizado: Credenciales incorrectas", content = @Content(mediaType = "application/json", examples = @ExampleObject(value = "{\"message\": \"Email o contraseña incorrectos.\"}"))),
            @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json", examples = @ExampleObject(value = "{\"message\": \"Error interno del servidor: ...\"}")))
    })
    public ResponseEntity<?> login(@RequestBody User credentials) {
        try {
            // lógica de autenticación
            Optional<User> user = userService.authenticate(credentials.getEmail(), credentials.getPassword());
            if (user.isPresent()) {
                // necesito guardar el email, y la contraseña en el token
                String token = jwtAuthFilter.generateToken(user.get().getEmail());
                System.out.println("Login exitoso para email: " + credentials.getEmail());
                return ResponseEntity.ok(Collections.singletonMap("token", token));
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("Email o contraseña incorrectos.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error interno del servidor: " + e.getMessage());
        }

    }
}
