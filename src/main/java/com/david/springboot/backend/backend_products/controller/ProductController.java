package com.david.springboot.backend.backend_products.controller;

import java.util.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import com.david.springboot.backend.backend_products.DTOs.ProductDTO;
import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;

import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.media.*;
import jakarta.validation.Valid;

@RestController
@CrossOrigin(origins = { "http://localhost:3000", "http://localhost:8080" })
@RequestMapping("/api/products")

public class ProductController {

  @Autowired
  private ProductRepository productRepo;

  @GetMapping
  @Operation(summary = "Obtener todos los productos", description = "Recupera una lista de todos los productos disponibles.", responses = {
      @ApiResponse(responseCode = "200", description = "Lista de productos devuelta exitosamente", content = @Content(mediaType = "application/json", array = @ArraySchema(schema = @Schema(implementation = Product.class)))),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<List<Product>> findAll() {
    List<Product> products = (List<Product>) productRepo.findAll();
    return ResponseEntity.ok(products);
  }

  @GetMapping("{id}")
  @Operation(summary = "Obtener un producto por ID", description = "Recupera un producto específico utilizando su ID único.", responses = {
      @ApiResponse(responseCode = "200", description = "Producto encontrado y devuelto exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = Product.class))),
      @ApiResponse(responseCode = "404", description = "Producto no encontrado", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<Product> findById(@PathVariable Long id) {
    Optional<Product> productOpt = productRepo.findById(id);
    return productOpt
        .map(product -> ResponseEntity.ok(product))
        .orElse(ResponseEntity.notFound().build());
  }

  @PostMapping
  @Operation(summary = "Crear un nuevo producto", description = "Crea un nuevo producto con los datos proporcionados en el cuerpo de la solicitud.", responses = {
      @ApiResponse(responseCode = "201", description = "Producto creado exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = Product.class))),
      @ApiResponse(responseCode = "400", description = "Datos inválidos en la solicitud", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<?> createProduct(@Valid @RequestBody ProductDTO productDTO, BindingResult result) {
    if (result.hasErrors()) {
      Map<String, String> err = new HashMap<>();
      result.getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
      return ResponseEntity.badRequest().body(err);
    }
    try {
      Product productToCreate = new Product();
      productToCreate.setName(productDTO.getName());
      productToCreate.setPrice(productDTO.getPrice());
      productToCreate.setQuantity(productDTO.getQuantity());
      productToCreate.setDescription(productDTO.getDescription());
      Product savedPro = productRepo.save(productToCreate);
      return ResponseEntity.status(HttpStatus.CREATED).body(savedPro);
    } catch (Exception e) {
      e.printStackTrace();
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  @PutMapping("{id}")
  @Operation(summary = "Actualizar un producto existente", description = "Actualiza los detalles de un producto existente utilizando su ID y los datos proporcionados en el cuerpo de la solicitud.", responses = {
      @ApiResponse(responseCode = "200", description = "Producto actualizado exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = Product.class))),
      @ApiResponse(responseCode = "400", description = "Datos inválidos en la solicitud", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "404", description = "Producto no encontrado", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<?> updateProduct(@PathVariable Long id, @Valid @RequestBody ProductDTO productDTO,
      BindingResult result) {
    if (result.hasErrors()) {
      Map<String, String> err = new HashMap<>();
      result.getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
      return ResponseEntity.badRequest().body(err);
    }
    try {
      Optional<Product> existingProductOpt = productRepo.findById(id);
      if (!existingProductOpt.isPresent())
        return ResponseEntity.notFound().build();

      Product productToUpdate = existingProductOpt.get();
      productToUpdate.setName(productDTO.getName());
      productToUpdate.setPrice(productDTO.getPrice());
      productToUpdate.setQuantity(productDTO.getQuantity());
      productToUpdate.setDescription(productDTO.getDescription());
      Product updatedProduct = productRepo.save(productToUpdate);
      return ResponseEntity.ok(updatedProduct);
    } catch (Exception e) {
      e.printStackTrace();
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }

  }

  @DeleteMapping("{id}")
  @Operation(summary = "Eliminar un producto", description = "Elimina un producto existente utilizando su ID.", responses = {
      @ApiResponse(responseCode = "204", description = "Producto eliminado exitosamente", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "404", description = "Producto no encontrado", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<?> deleteProduct(@PathVariable Long id) {
    try {
      if (productRepo.existsById(id)) {
        productRepo.deleteById(id);
        System.out.println("Producto eliminado con éxito: " + id);
        return ResponseEntity.noContent().build();
      } else {
        return ResponseEntity.notFound().build();
      }
    } catch (Exception e) {
      e.printStackTrace();
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body("Error interno en el servidor: " + e.getMessage());
    }
  }
}
