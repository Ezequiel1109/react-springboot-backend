package com.david.springboot.backend.backend_products.controller;

import com.david.springboot.backend.backend_products.services.UserService;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import com.fasterxml.jackson.databind.DeserializationFeature;

import java.util.*;

//import com.fasterxml.jackson.core.type.TypeReference;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import com.david.springboot.backend.backend_products.SecurityConfig.DataConfig;
import com.david.springboot.backend.backend_products.entities.User;
//"http://localhost:5173"

@RestController
@RequestMapping("/user")
@CrossOrigin(origins = {"http://localhost:3000"})
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private DataConfig dataConfig;

    // Endpoint for user registration
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user /*String jsonPayload*/) {
        try{
            System.out.println("REGISTER - DATOS RECIBIDOS");
            System.out.println("Username: " + user.getUsername());
            System.out.println("Email: " + user.getEmail());
            System.out.println("Password: " + (user.getPassword() != null ? "[PRESENTE]" : "[FALTANTE]"));
            System.out.println("=================================");
            
            //validacion
            if(user.getUsername() == null || user.getUsername().trim().isEmpty()) return ResponseEntity.badRequest()
                    .body("El nombre de usuario es obligatorio.");
            if(user.getPassword() == null || user.getPassword().trim().isEmpty()) return ResponseEntity.badRequest()
                    .body("La contraseña es obligatoria.");
            if(user.getEmail() == null || user.getEmail().trim().isEmpty()) return ResponseEntity.badRequest()
                    .body("El email es obligatorio.");
                    

            User userRegister = userService.register(user);
            System.out.println("Usuario registrado exitosamente con id: " + userRegister.getId());
            return ResponseEntity.ok(userRegister);

        }catch(Exception e){
            System.err.println("Error en el registro: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error interno en el servidor: " + e.getMessage());
        }
    }

    // Endpoint for user login
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User credentials /*String cred*/) {
        try {
            System.out.println("=== LOGIN - DATOS RECIBIDOS ===");
            System.out.println("Username: " + credentials.getUsername());
            System.out.println("Password: " + (credentials.getPassword() != null ? "[PRESENTE]" : "[NULL]"));
            System.out.println("================================");
            
            // Validaciones básicas
            if (credentials.getUsername() == null || credentials.getUsername().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("El nombre de usuario es obligatorio");
            }
            if (credentials.getPassword() == null || credentials.getPassword().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("La contraseña es obligatoria");
            }
            
            //lógica de autenticación
            Optional<User> user = userService.authenticate(credentials.getUsername(), credentials.getPassword());
            if (user.isPresent()) {
                String token = dataConfig.generateToken(user.get().getUsername());
                System.out.println("Login exitoso para usuario: " + credentials.getUsername());
                return ResponseEntity.ok(Map.of("token", token));
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("message", "Usuario o contraseña incorrectos."));
            }
        } catch (Exception e) {
            System.err.println("Error en el proceso de login: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error interno del servidor: " + e.getMessage());
        }

    }
}
