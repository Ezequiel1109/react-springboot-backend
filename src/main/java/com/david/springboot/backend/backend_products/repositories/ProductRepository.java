package com.david.springboot.backend.backend_products.repositories;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.web.bind.annotation.CrossOrigin;

import com.david.springboot.backend.backend_products.entities.Product;

@CrossOrigin(origins = {"http://localhost:3000"})
@RepositoryRestResource(path = "products")
public interface ProductRepository extends JpaRepository<Product, Long> {
 // La interfaz extiende JpaRepository, proporcionando métodos CRUD para la entidad Product con clave primaria de tipo Long.
 Page<Product> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
