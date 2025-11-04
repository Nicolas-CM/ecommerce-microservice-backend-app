package com.selimhorri.app.config;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import com.selimhorri.app.domain.Address;
import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.repository.CredentialRepository;
import com.selimhorri.app.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
@RequiredArgsConstructor
public class DefaultUserConfig {

    private final UserRepository userRepository;
    private final CredentialRepository credentialRepository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @EventListener(ApplicationReadyEvent.class)
    public void init() {
        // Verificar si ya existe el usuario testuser
        if (credentialRepository.findByUsername("testuser").isEmpty()) {
            log.info("*** Creating default testuser ***");

            // Crear credenciales de testuser
            Credential testCredential = Credential.builder()
                    .username("testuser")
                    .password(passwordEncoder.encode("testuser"))
                    .roleBasedAuthority(RoleBasedAuthority.ROLE_ADMIN)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            // Crear usuario testuser
            User testUser = User.builder()
                    .firstName("Test")
                    .lastName("User")
                    .imageUrl("https://via.placeholder.com/150")
                    .email("testuser@ecommerce.com")
                    .phone("+57 300 1111111")
                    .build();

            // Crear dirección por defecto
            Address testAddress = Address.builder()
                    .fullAddress("Test Address - Street 456")
                    .postalCode("111111")
                    .city("Test City")
                    .user(testUser)
                    .build();

            // Asignar relaciones
            testUser.setCredential(testCredential);
            testCredential.setUser(testUser);
            testUser.getAddresses().add(testAddress);

            // Guardar
            userRepository.save(testUser);
            credentialRepository.save(testCredential);

            log.info("*** Default testuser created successfully ***");
            log.info("*** Username: testuser ***");
            log.info("*** Password: testuser ***");
            log.info("*** Role: ROLE_ADMIN ***");
        } else {
            log.info("*** Testuser already exists ***");
        }
    }

}
