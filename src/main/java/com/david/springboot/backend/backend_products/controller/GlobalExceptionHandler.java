package com.david.springboot.backend.backend_products.controller;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<?> handleJsonParseError(HttpMessageNotReadableException ex) {
        System.err.println("=== ERROR DE DESERIALIZACIÓN JSON ===");
        System.err.println("Mensaje: " + ex.getMessage());
        ex.printStackTrace();
        System.err.println("=====================================");
        
        String message = "Error en el formato JSON. ";
        
        // Identificar el tipo específico de error
        if (ex.getMessage().contains("Cannot deserialize value of type `java.lang.String` from Object value")) {
            message += "Se esperaba un texto pero se recibió un objeto. Verifica que los campos sean strings simples.";
        } else if (ex.getMessage().contains("Cannot deserialize value of type")) {
            message += "Tipo de dato incorrecto en algún campo del JSON.";
        } else {
            message += "El JSON enviado no tiene el formato correcto.";
        }
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of(
                    "error", "JSON_PARSE_ERROR",
                    "message", message,
                    "details", ex.getMessage()
                ));
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleGenericError(Exception ex) {
        System.err.println("=== ERROR GENÉRICO ===");
        System.err.println("Mensaje: " + ex.getMessage());
        ex.printStackTrace();
        System.err.println("======================");
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "error", "INTERNAL_ERROR",
                    "message", "Error interno del servidor"
                ));
    }
}
