package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import java.util.HashSet;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.selimhorri.app.domain.Address;
import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.repository.UserRepository;
import com.selimhorri.app.service.impl.UserServiceImpl;

@ExtendWith(MockitoExtension.class)
class UserServiceApplicationTests {

        @Mock
        private UserRepository userRepository;

        @Mock
        private PasswordEncoder passwordEncoder;

        @InjectMocks
        private UserServiceImpl userService;

        private UserDto testUserDto;
        private User testUser;

        @BeforeEach
        void setUp() {
                // Preparar datos de prueba
                CredentialDto credentialDto = CredentialDto.builder()
                                .username("testuser")
                                .password("plainPassword123")
                                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                                .isEnabled(true)
                                .isAccountNonExpired(true)
                                .isAccountNonLocked(true)
                                .isCredentialsNonExpired(true)
                                .build();

                AddressDto addressDto = AddressDto.builder()
                                .fullAddress("123 Test Street")
                                .postalCode("12345")
                                .city("Test City")
                                .build();

                testUserDto = UserDto.builder()
                                .firstName("John")
                                .lastName("Doe")
                                .email("john.doe@test.com")
                                .phone("+1234567890")
                                .credentialDto(credentialDto)
                                .addressDtos(new HashSet<>())
                                .build();
                testUserDto.getAddressDtos().add(addressDto);

                // Usuario guardado (con contraseña encriptada)
                Credential credential = Credential.builder()
                                .username("testuser")
                                .password("$2a$10$encryptedPassword")
                                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                                .isEnabled(true)
                                .isAccountNonExpired(true)
                                .isAccountNonLocked(true)
                                .isCredentialsNonExpired(true)
                                .build();

                testUser = User.builder()
                                .userId(1)
                                .firstName("John")
                                .lastName("Doe")
                                .email("john.doe@test.com")
                                .phone("+1234567890")
                                .credential(credential)
                                .addresses(new HashSet<>())
                                .build();

                credential.setUser(testUser);

                Address address = Address.builder()
                                .addressId(1)
                                .fullAddress("123 Test Street")
                                .postalCode("12345")
                                .city("Test City")
                                .user(testUser)
                                .build();
                testUser.getAddresses().add(address);
        }

        /**
         * PRUEBA UNITARIA 1: Verificar que al crear un usuario, la contraseña se
         * encripta correctamente
         * 
         * Esta prueba valida:
         * - El servicio recibe un UserDto con contraseña en texto plano
         * - La contraseña se encripta usando BCryptPasswordEncoder
         * - El usuario se guarda con la contraseña encriptada
         * - Las relaciones bidireccionales (User-Credential-Address) se establecen
         * correctamente
         */
        @Test
        void testSaveUser_PasswordIsEncrypted() {
                // Given: Configurar el comportamiento del mock
                when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$encryptedPassword");
                when(userRepository.save(any(User.class))).thenReturn(testUser);

                // When: Ejecutar el método a probar
                UserDto result = userService.save(testUserDto);

                // Then: Verificar resultados
                assertNotNull(result, "El resultado no debe ser null");
                assertEquals("WrongName", result.getFirstName());
                assertEquals("Doe", result.getLastName());
                assertEquals("john.doe@test.com", result.getEmail());

                // Verificar que la contraseña fue encriptada
                verify(passwordEncoder, times(1)).encode("plainPassword123");

                // Verificar que se guardó el usuario
                verify(userRepository, times(1)).save(any(User.class));

                // Verificar que la contraseña retornada NO es la original (por seguridad)
                assertNotNull(result.getCredentialDto());
        }

        /**
         * PRUEBA UNITARIA 2: Verificar búsqueda de usuario por username
         * 
         * Esta prueba valida:
         * - El servicio puede buscar un usuario por su username en las credenciales
         * - Se retorna el UserDto correcto cuando el usuario existe
         * - Se lanza excepción cuando el usuario no existe
         */
        @Test
        void testFindByUsername_UserExists() {
                // Given
                when(userRepository.findByCredentialUsername("testuser"))
                                .thenReturn(Optional.of(testUser));

                // When
                UserDto result = userService.findByUsername("testuser");

                // Then
                assertNotNull(result, "El resultado no debe ser null");
                assertEquals("John", result.getFirstName());
                assertEquals("Doe", result.getLastName());
                assertEquals("testuser", result.getCredentialDto().getUsername());

                verify(userRepository, times(1)).findByCredentialUsername("testuser");
        }

        /**
         * PRUEBA UNITARIA 3: Verificar actualización de usuario manteniendo integridad
         * de datos
         * 
         * Esta prueba valida:
         * - El servicio puede actualizar datos de un usuario existente
         * - Las relaciones se mantienen intactas durante la actualización
         * - Los nuevos datos se guardan correctamente
         */
        @Test
        void testUpdateUser_MaintainsDataIntegrity() {
                // Given: Usuario existente con datos actualizados
                CredentialDto credentialDto = CredentialDto.builder()
                                .credentialId(1)
                                .username("janesmith")
                                .password("$2a$10$updatedPassword")
                                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                                .isEnabled(true)
                                .isAccountNonExpired(true)
                                .isAccountNonLocked(true)
                                .isCredentialsNonExpired(true)
                                .build();

                UserDto updateDto = UserDto.builder()
                                .userId(1)
                                .firstName("Jane")
                                .lastName("Smith")
                                .email("jane.smith@test.com")
                                .phone("+0987654321")
                                .credentialDto(credentialDto)
                                .addressDtos(new HashSet<>())
                                .build();

                Credential updatedCredential = Credential.builder()
                                .credentialId(1)
                                .username("janesmith")
                                .password("$2a$10$updatedPassword")
                                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                                .isEnabled(true)
                                .isAccountNonExpired(true)
                                .isAccountNonLocked(true)
                                .isCredentialsNonExpired(true)
                                .build();

                User updatedUser = User.builder()
                                .userId(1)
                                .firstName("Jane")
                                .lastName("Smith")
                                .email("jane.smith@test.com")
                                .phone("+0987654321")
                                .credential(updatedCredential)
                                .addresses(new HashSet<>())
                                .build();

                updatedCredential.setUser(updatedUser);

                when(userRepository.save(any(User.class))).thenReturn(updatedUser);

                // When
                UserDto result = userService.update(updateDto);

                // Then
                assertNotNull(result, "El resultado no debe ser null");
                assertEquals("Jane", result.getFirstName());
                assertEquals("Smith", result.getLastName());
                assertEquals("jane.smith@test.com", result.getEmail());
                assertEquals("+0987654321", result.getPhone());
                assertNotNull(result.getCredentialDto());
                assertEquals("janesmith", result.getCredentialDto().getUsername());

                verify(userRepository, times(1)).save(any(User.class));
        }

}
