package com.david.springboot.backend.backend_products.repositories;

import org.springframework.data.repository.CrudRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.web.bind.annotation.CrossOrigin;

import com.david.springboot.backend.backend_products.entities.Product;

@CrossOrigin(origins = {"http://localhost:3000"})
@RepositoryRestResource(path = "products")
public interface ProductRepository extends CrudRepository<Product, Long> {
 // La interfaz extiende CrudRepository, proporcionando métodos CRUD para la entidad Product con clave primaria de tipo Long.
}
