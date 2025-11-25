package com.david.springboot.backend.backend_products.controller;

import java.util.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.*;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import com.david.springboot.backend.backend_products.DTOs.PageResponseDTO;
import com.david.springboot.backend.backend_products.DTOs.ProductDTO;
import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;

import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.media.*;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@CrossOrigin(origins = { "http://localhost:3000", "http://localhost:64410" })
@RequestMapping("/api/products")

public class ProductController {

  @Autowired
  private ProductRepository productRepo;

  private static final Logger log = LoggerFactory.getLogger(ProductController.class);

  @GetMapping
  @Operation(summary = "Obtener todos los productos paginados", description = "Recupera una lista de todos los productos disponibles.", responses = {
      @ApiResponse(responseCode = "200", description = "Lista de productos devuelta exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = PageResponseDTO.class))),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<PageResponseDTO<ProductDTO>> findAll(@RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
        log.info("Request: GET /api/products?page={}&size={}", page, size);
    try {
      Pageable pageable = PageRequest.of(page, size);
      Page<Product> productPage = productRepo.findAll(pageable);
      Page<ProductDTO> dtoPage = productPage.map(this::toDTO);
      PageResponseDTO<ProductDTO> responseDTO = new PageResponseDTO<>(dtoPage);

      log.info("Productos paginados obtenidos exitosamente: página {}, tamaño {}, total elementos {}",
          responseDTO.getPageNumber(), responseDTO.getPageSize(), responseDTO.getTotalElements());
      return ResponseEntity.ok(responseDTO);
    } catch (Exception e) {
      log.error("Error al obtener productos paginados", e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  @GetMapping("{id}")
  @Operation(summary = "Obtener un producto por ID", description = "Recupera un producto específico utilizando su ID único.", responses = {
      @ApiResponse(responseCode = "200", description = "Producto encontrado y devuelto exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = Product.class))),
      @ApiResponse(responseCode = "404", description = "Producto no encontrado", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<ProductDTO> findById(@PathVariable Long id) {
    log.info("Request: GET /api/products/{} - obtener producto por id", id);
    try {
      Optional<Product> productOpt = productRepo.findById(id);
      if(productOpt.isPresent()){
        ProductDTO prodDTO = toDTO(productOpt.get());
        log.info("Producto obtenido exitosamente: {}", id);
        return ResponseEntity.ok(prodDTO);
      }else{
        log.warn("Producto no encontrado: {}", id);
        return ResponseEntity.notFound().build();
      }
    } catch (Exception e) {
      log.error("Error al obtener producto id={}", id, e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  @PostMapping
  @Operation(summary = "Crear un nuevo producto", description = "Crea un nuevo producto con los datos proporcionados en el cuerpo de la solicitud.", responses = {
      @ApiResponse(responseCode = "201", description = "Producto creado exitosamente", content = @Content(mediaType = "application/json", schema = @Schema(implementation = Product.class))),
      @ApiResponse(responseCode = "400", description = "Datos inválidos en la solicitud", content = @Content(mediaType = "application/json")),
      @ApiResponse(responseCode = "500", description = "Error interno del servidor", content = @Content(mediaType = "application/json"))
  })
  public ResponseEntity<?> createProduct(@Valid @RequestBody ProductDTO productDTO, BindingResult result) {
    log.info("Request:POST /api/products - crear producto: {}", productDTO);
    if (result.hasErrors()) {
      Map<String, String> err = new HashMap<>();
      result.getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
      log.warn("Error en la solicitud: {}", err);
      return ResponseEntity.badRequest().body(err);
    }
    try {
      Product productToCreate = toEntity(productDTO);
      productToCreate.setId(null);
      Product savedPro = productRepo.save(productToCreate);
      ProductDTO savedProDTO = toDTO(savedPro);
      log.info("Producto creado exitosamente: {}", savedProDTO);
      return ResponseEntity.status(HttpStatus.CREATED).body(savedProDTO);
    }catch(ObjectOptimisticLockingFailureException e) {
      log.error("Conflicto de concurrencia al crear el producto: {}", productDTO, e);
      return ResponseEntity.status(HttpStatus.CONFLICT).body("Conflicto de concurrencia al crear el producto. Por favor, inténtelo de nuevo.");
    }catch (Exception e) {
      log.error("Error al crear el producto: {}", productDTO, e);
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
    log.info("Request: PUT /api/products/{} - actualizar producto: {}", id, productDTO);
    if (result.hasErrors()) {
      Map<String, String> err = new HashMap<>();
      result.getFieldErrors().forEach(error -> err.put(error.getField(), error.getDefaultMessage()));
      log.warn("Error en la solicitud: {}", err);
      return ResponseEntity.badRequest().body(err);
    }
    try {
      Optional<Product> existingProductOpt = productRepo.findById(id);
      if (!existingProductOpt.isPresent()) {
        log.warn("Producto no encontrado para actualizar con ID: {}", id);
        return ResponseEntity.notFound().build();
      }

      Product productToUpdate = existingProductOpt.get();
      productToUpdate.setName(productDTO.getName());
      productToUpdate.setPrice(productDTO.getPrice());
      productToUpdate.setQuantity(productDTO.getQuantity());
      productToUpdate.setDescription(productDTO.getDescription());

      Product updatedProduct = productRepo.save(productToUpdate);
      ProductDTO updatedProductDTO = toDTO(updatedProduct);
      log.info("Producto actualizado exitosamente: {}", id);
      return ResponseEntity.ok(updatedProductDTO);
      
    } catch (Exception e) {
      log.error("Error al actualizar el producto con ID {}: {}", id, e.getMessage(), e);
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
    log.info("Request: DELETE /api/products/{} - eliminar producto", id);
    try {
      if (productRepo.existsById(id)) {
        productRepo.deleteById(id);
        log.info("Producto eliminado con éxito: {}", id);
        return ResponseEntity.noContent().build();
      } else {
        log.warn("Intento de eliminar un producto que no existe: {}", id);
        return ResponseEntity.notFound().build();
      }
    } catch (Exception e) {
      log.error("Error al eliminar el producto con ID {}: {}", id, e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body("Error interno en el servidor: " + e.getMessage());
    }
  }

  // Helpers: mapeo entidad DTO
  private ProductDTO toDTO(Product product) {
    if (product == null)
      return null;
    ProductDTO dto = new ProductDTO();
    dto.setId(product.getId());
    dto.setName(product.getName());
    dto.setPrice(product.getPrice());
    dto.setQuantity(product.getQuantity());
    dto.setDescription(product.getDescription());
    return dto;
  }

  private Product toEntity(ProductDTO dto) {
    if (dto == null)
      return null;
    Product product = new Product();
    if (dto.getId() != null) {
      product.setId(dto.getId());
    }
    product.setName(dto.getName());
    product.setPrice(dto.getPrice());
    product.setQuantity(dto.getQuantity());
    product.setDescription(dto.getDescription());
    return product;
  }
}
