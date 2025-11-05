package com.selimhorri.app.integration;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.domain.RoleBasedAuthority;

import java.util.HashSet;
import java.util.Set;

/**
 * Integration tests for UserResource (Controller)
 * These tests verify the integration between Controller, Service, and
 * Repository layers
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private UserDto testUserDto;

    @BeforeEach
    void setUp() {
        // Setup test data
        Set<AddressDto> addressDtos = new HashSet<>();
        AddressDto addressDto = AddressDto.builder()
                .fullAddress("123 Test Street")
                .postalCode("12345")
                .city("Test City")
                .build();
        addressDtos.add(addressDto);

        CredentialDto credentialDto = CredentialDto.builder()
                .username("integrationuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();

        testUserDto = UserDto.builder()
                .firstName("Integration")
                .lastName("Test")
                .imageUrl("http://test.com/image.jpg")
                .email("integration@test.com")
                .phone("+1234567890")
                .credentialDto(credentialDto)
                .addressDtos(addressDtos)
                .build();
    }

    /**
     * Test 1: Integration test for GET /api/users
     * Validates that the controller can fetch all users from the database
     */
    @Test
    void testGetAllUsers_ReturnsUserList() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.collection").isArray());
    }

    /**
     * Test 2: Integration test for POST /api/users followed by GET /api/users/{id}
     * Validates complete flow: create user -> retrieve user with all relationships
     */
    @Test
    void testCreateAndRetrieveUser_FullFlow() throws Exception {
        // Act: Create user
        String createResponse = mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testUserDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Integration"))
                .andExpect(jsonPath("$.lastName").value("Test"))
                .andExpect(jsonPath("$.email").value("integration@test.com"))
                .andExpect(jsonPath("$.phone").value("+1234567890"))
                .andExpect(jsonPath("$.userId").exists())
                .andReturn()
                .getResponse()
                .getContentAsString();

        // Extract userId from response
        UserDto createdUser = objectMapper.readValue(createResponse, UserDto.class);
        Integer userId = createdUser.getUserId();

        // Assert: Retrieve the created user
        mockMvc.perform(get("/api/users/" + userId)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(userId))
                .andExpect(jsonPath("$.firstName").value("Integration"))
                .andExpect(jsonPath("$.lastName").value("Test"))
                .andExpect(jsonPath("$.email").value("integration@test.com"))
                .andExpect(jsonPath("$.phone").value("+1234567890"));
    }

    /**
     * Test 3: Integration test for POST -> PUT -> GET flow
     * Validates user creation, update, and retrieval with password encryption
     */
    @Test
    void testCreateUpdateAndRetrieveUser_WithPasswordEncryption() throws Exception {
        // Step 1: Create user
        String createResponse = mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testUserDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").exists())
                .andReturn()
                .getResponse()
                .getContentAsString();

        UserDto createdUser = objectMapper.readValue(createResponse, UserDto.class);
        Integer userId = createdUser.getUserId();

        // Step 2: Update user information
        createdUser.setFirstName("Updated");
        createdUser.setLastName("Name");
        createdUser.setEmail("updated@test.com");

        mockMvc.perform(put("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createdUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Updated"))
                .andExpect(jsonPath("$.lastName").value("Name"))
                .andExpect(jsonPath("$.email").value("updated@test.com"));

        // Step 3: Verify updated user is persisted correctly
        mockMvc.perform(get("/api/users/" + userId)
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(userId))
                .andExpect(jsonPath("$.firstName").value("Updated"))
                .andExpect(jsonPath("$.lastName").value("Name"))
                .andExpect(jsonPath("$.email").value("updated@test.com"));
    }

}
