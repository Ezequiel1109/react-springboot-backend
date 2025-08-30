package com.david.springboot.backend.backend_products.services;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.david.springboot.backend.backend_products.SecurityConfig.DataConfig;
import com.david.springboot.backend.backend_products.entities.User;
import com.david.springboot.backend.backend_products.repositories.UserRepository;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepo;

    @Autowired
    private DataConfig passEncoder;

    public User register(User user){
        // Encode the password before saving
        user.setPassword(passEncoder.encoder().encode(user.getPassword()));
        return userRepo.save(user);
    }

    public Optional<User> authenticate(String username, String password) {
        return userRepo.findByUsername(username)
                .filter(user -> passEncoder.encoder().matches(password, user.getPassword()));
    }
}
