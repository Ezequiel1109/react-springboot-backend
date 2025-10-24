package com.david.springboot.backend.backend_products;

import static org.mockito.Mockito.*;

import java.util.Optional;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertFalse;
import static org.mockito.ArgumentMatchers.anyString;

import org.junit.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.Before;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.david.springboot.backend.backend_products.entities.User;
import com.david.springboot.backend.backend_products.repositories.UserRepository;
import com.david.springboot.backend.backend_products.services.UserService;

@ExtendWith(org.mockito.junit.jupiter.MockitoExtension.class)
class UserServicesTest {
    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Before
    public void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    public void testRegisterUserAndReturnSaved(){
        // Implementar el test para el método register del UserService
        User toSave = new User();
        toSave.setUsername("testuser");
        toSave.setEmail("testuser@example.com");
        toSave.setPassword("password123");

        User saved = new User();
        saved.setId(1L);
        saved.setUsername("testuser");
        saved.setEmail("testuser@example.com");

        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(toSave)).thenReturn(saved);

        User rUser = userService.register(toSave);
        assertNotNull(rUser);
        assertEquals(Long.valueOf(1L), rUser.getId());
        verify(userRepository, times(1)).save(any(User.class));
        verify(passwordEncoder, times(1)).encode("password123");
        
    }

    @Test
    public void test_registerDuplicateEamil_shouldThrowDataIntegrityViolationException() {
        // Implementar el test para el caso de email duplicado
        User toSave = new User();
        toSave.setUsername("testuser");
        toSave.setEmail("testuser@example.com");
        toSave.setPassword("password123");

        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenThrow(new DataIntegrityViolationException("Duplicate entry 'testuser@example.com'"));

        DataIntegrityViolationException ex = assertThrows(DataIntegrityViolationException.class, () -> userService.register(toSave));
        assertTrue(ex.getMessage().contains("Duplicate entry 'testuser@example.com'"));
    }

    @Test
    public void test_authenticateExistingCredentials_shouldReturnUser(){
        // Implementar el test para el método authenticate del UserService
        String email = "testuser@example.com";
        String password = "password123";
        User existingUser = new User();
        existingUser.setId(2L);
        existingUser.setEmail(email);
        existingUser.setPassword("encodedPassword");

        when(userRepository.findByEmail(eq(email))).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches(eq(password), eq(existingUser.getPassword()))).thenReturn(true);

        Optional<User> result =userService.authenticate(email, password);
        assertTrue(result.isPresent());
        assertEquals(email, result.get().getEmail());
        verify(userRepository, times(1)).findByEmail(email);
    }

    @Test
    public void test_authenticate_wrongCredentials_shouldReturnEmpty(){
        // Implementar el test para el método authenticate del UserService con credenciales incorrectas
        String email = "testuser@example.com";
        String password = "wrongPassword";

        User existingUser = new User();
        existingUser.setId(2L);
        existingUser.setEmail(email);
        existingUser.setPassword("encodedPassword");

        when(userRepository.findByEmail(eq(email))).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches(eq(password), eq(existingUser.getPassword()))).thenReturn(false);

        Optional<User> result = userService.authenticate(email, password);
        assertFalse(result.isPresent());
    }

}
