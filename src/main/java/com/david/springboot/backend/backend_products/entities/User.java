package com.david.springboot.backend.backend_products.entities;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonSetter;
import jakarta.persistence.*;  

@Entity
@Table(name="users")
@JsonIgnoreProperties(ignoreUnknown = true)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;
    private String password;
    private String email;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
    
    // Método especial para manejar username si viene como objeto
    @JsonSetter("username")
    public void setUsernameFromJson(Object usernameValue) {
        if (usernameValue == null) {
            this.username = null;
        } else if (usernameValue instanceof String) {
            this.username = (String) usernameValue;
        } else {
            // Si viene un objeto, convertir a string
            this.username = usernameValue.toString();
        }
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
    
    // Método especial para manejar password si viene como objeto
    @JsonSetter("password")
    public void setPasswordFromJson(Object passwordValue) {
        if (passwordValue == null) {
            this.password = null;
        } else if (passwordValue instanceof String) {
            this.password = (String) passwordValue;
        } else {
            // Si viene un objeto, convertir a string
            this.password = passwordValue.toString();
        }
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
    
    // Método especial para manejar email si viene como objeto
    @JsonSetter("email")
    public void setEmailFromJson(Object emailValue) {
        if (emailValue == null) {
            this.email = null;
        } else if (emailValue instanceof String) {
            this.email = (String) emailValue;
        } else {
            // Si viene un objeto, convertir a string
            this.email = emailValue.toString();
        }
    }

}
