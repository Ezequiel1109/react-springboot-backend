package com.david.springboot.backend.backend_products.controller;

import java.util.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import com.david.springboot.backend.backend_products.entities.Product;
import com.david.springboot.backend.backend_products.repositories.ProductRepository;

@RestController
@CrossOrigin(origins = {"http://localhost:3000"})
@RequestMapping("/api/products")

public class ProductController {
    
    @Autowired
    private ProductRepository productRepo;

    @GetMapping
    public List<Product> findAll(){
        return ((List<Product>) productRepo.findAll());
    }

    @GetMapping("{id}")
    public ResponseEntity<Product> findById(@PathVariable Long id){
        Optional<Product> productOpt = productRepo.findById(id);
        return productOpt
            .map(product -> ResponseEntity.ok(product))
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<?> createProduct(@RequestBody Product product) {
      try{

        //validaciones
        if(product.getName() == null || product.getName().trim().isEmpty()) {
          return ResponseEntity.badRequest().body("El nombre del producto es obligatorio.");
        }
        if(product.getPrice() == null || product.getPrice() <= 0) {
          return ResponseEntity.badRequest().body("El precio del producto es obligatorio y debe ser mayor que cero.");
        }
        if(product.getQuantity() == null || product.getQuantity() < 0) {
          return ResponseEntity.badRequest().body("La cantidad del producto es obligatoria y no puede ser negativa.");
        }
        if(product.getDescription() == null || product.getDescription().trim().isEmpty()) {
          return ResponseEntity.badRequest().body("La descripción del producto es obligatoria.");
        }
        Product savedPro = productRepo.save(product);
        System.out.println("Producto creado con éxito: " + savedPro.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(savedPro);

      }catch(Exception e){/*
          System.err.println("Error al crear producto: " + e.getMessage());
      */
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Error interno del servidor: " + e.getMessage());
      }
    }

    @PutMapping("{id}")
    public ResponseEntity<?> updateProduct(@PathVariable Long id, @RequestBody Product product) {
       try{

        Optional<Product> existingProductOpt = productRepo.findById(id);
        if(!existingProductOpt.isPresent()) return ResponseEntity.notFound().build();

        //validaciones
        if(product.getName() == null || product.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("El nombre del producto es obligatorio.");
        }
        if(product.getPrice() == null || product.getPrice() <= 0) {
            return ResponseEntity.badRequest().body("El precio del producto es obligatorio y debe ser mayor que cero.");
        }
        if(product.getQuantity() == null || product.getQuantity() < 0) {
            return ResponseEntity.badRequest().body("La cantidad del producto es obligatoria y no puede ser negativa.");
        }
        if(product.getDescription() == null || product.getDescription().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("La descripción del producto es obligatoria.");
        }
        product.setId(id);
        Product updatedProduct = productRepo.save(product);
        System.out.println("Producto actualizado exitosamente");

        return ResponseEntity.ok(updatedProduct);

       }catch(Exception e){
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Error interno del servidor: " + e.getMessage());
       }
    }

    @DeleteMapping("{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        if(productRepo.existsById(id)){
            productRepo.deleteById(id);
            System.out.println("Producto eliminado con éxito: " + id);
            return ResponseEntity.noContent().build();
        }else{
            return ResponseEntity.notFound().build();
        }
        
    }

}
