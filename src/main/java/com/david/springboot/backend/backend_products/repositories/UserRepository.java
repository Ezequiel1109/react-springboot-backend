package com.david.springboot.backend.backend_products.repositories;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.web.bind.annotation.CrossOrigin;

import com.david.springboot.backend.backend_products.entities.User;

@CrossOrigin(origins = {"http://localhost:3000"})
@RepositoryRestResource(path = "user")
public interface UserRepository extends JpaRepository<User, Long> {
    // La interfaz extiende CrudRepository, proporcionando métodos CRUD para la entidad User con clave primaria de tipo Long.
    Optional<User> findByUsername(String username);
}
