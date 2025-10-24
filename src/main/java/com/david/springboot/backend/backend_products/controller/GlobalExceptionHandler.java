package com.david.springboot.backend.backend_products.controller;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(HttpMessageNotReadableException.class)
    @Operation(summary = "Maneja errores de deserialización JSON", description = "Captura y maneja errores que ocurren cuando el JSON enviado en la solicitud no puede ser deserializado correctamente.", responses = {
            @ApiResponse(responseCode = "400", description = "Error en el formato JSON"),
            @ApiResponse(responseCode = "500", description = "Error interno del servidor")
    })
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
                        "details", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    @Operation(summary = "Maneja errores genéricos del servidor", description = "Captura y maneja cualquier error genérico que ocurra en el servidor.", responses = {
            @ApiResponse(responseCode = "500", description = "Error interno del servidor")
    })
    public ResponseEntity<?> handleGenericError(Exception ex) {
        System.err.println("=== ERROR GENÉRICO ===");
        System.err.println("Mensaje: " + ex.getMessage());
        ex.printStackTrace();
        System.err.println("======================");

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                        "error", "INTERNAL_ERROR",
                        "message", "Error interno del servidor"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @Operation(summary = "Maneja errores de validación de datos", description = "Captura y maneja errores de validación que ocurren cuando los datos enviados en la solicitud no son válidos.", responses = {
            @ApiResponse(responseCode = "400", description = "Error de validación de datos"),
            @ApiResponse(responseCode = "500", description = "Error interno del servidor")
    })
    public ResponseEntity<?> handleValidationErrorResponseEntity(MethodArgumentNotValidException ex) {
        Map<String, String> err = new java.util.HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "error", "VALIDATION_ERROR",
                "message", "Error de validación de datos",
                "details", err));
    }
}
