package com.david.springboot.backend.backend_products;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Optional;

import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.david.springboot.backend.backend_products.entities.User;
import com.david.springboot.backend.backend_products.repositories.UserRepository;
import com.david.springboot.backend.backend_products.services.UserService;

@ExtendWith(MockitoExtension.class)
class UserServicesTest {
    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    public void setUp() {

    }

    @Test
    @DisplayName("Test que registra al usuario y devuelve el usuario guardado")
    void testRegisterUserAndReturnSaved() {
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
        when(userRepository.save(any(User.class))).thenReturn(saved);

        User rUser = userService.register(toSave);
        assertNotNull(rUser);
        assertEquals(Long.valueOf(1L), rUser.getId());
        verify(userRepository, times(1)).save(any(User.class));
        verify(passwordEncoder, times(1)).encode("password123");

    }

    @Test
    @DisplayName("Test que registra un email duplicado y lanza una excepción")
    void test_registerDuplicateEamil_shouldThrowDataIntegrityViolationException() {
        // Implementar el test para el caso de email duplicado
        User toSave = new User();
        toSave.setUsername("testuser");
        toSave.setEmail("testuser@example.com");
        toSave.setPassword("password123");

        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("Duplicate entry 'testuser@example.com'"));

        DataIntegrityViolationException ex = assertThrows(DataIntegrityViolationException.class,
                () -> userService.register(toSave));
        assertTrue(ex.getMessage().contains("Duplicate entry 'testuser@example.com'"));
    }

    @Test
    @DisplayName("Test que autentica credenciales existentes y devuelve el usuario")
    void test_authenticateExistingCredentials_shouldReturnUser() {
        // Implementar el test para el método authenticate del UserService
        String email = "testuser@example.com";
        String password = "password123";
        User existingUser = new User();
        existingUser.setId(2L);
        existingUser.setEmail(email);
        existingUser.setPassword("encodedPassword");

        when(userRepository.findByEmail(eq(email))).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches(eq(password), eq(existingUser.getPassword()))).thenReturn(true);

        Optional<User> result = userService.authenticate(email, password);
        assertTrue(result.isPresent());
        assertEquals(email, result.get().getEmail());
        verify(userRepository, times(1)).findByEmail(email);
    }

    @Test
    @DisplayName("Test que autentica credenciales incorrectas y devuelve vacío")
    void test_authenticate_wrongCredentials_shouldReturnEmpty() {
        // Implementar el test para el método authenticate del UserService con
        // credenciales incorrectas
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
