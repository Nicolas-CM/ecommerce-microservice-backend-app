package com.selimhorri.app.integration;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.domain.id.FavouriteId;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.repository.FavouriteRepository;
import com.selimhorri.app.service.FavouriteService;

/**
 * Integration tests for Favourite Service communication with User and Product
 * services
 * Validates RestTemplate calls to multiple microservices
 */
@SpringBootTest
@Transactional
class FavouriteServiceIntegrationTest {

    @Autowired
    private FavouriteService favouriteService;

    @Autowired
    private FavouriteRepository favouriteRepository;

    @MockBean
    private RestTemplate restTemplate;

    private UserDto mockUserDto;
    private ProductDto mockProductDto;
    private Favourite savedFavourite;

    @BeforeEach
    void setUp() {
        // Setup mock user response from user-service
        mockUserDto = UserDto.builder()
                .userId(1)
                .firstName("Test")
                .lastName("User")
                .email("test@user.com")
                .phone("+1234567890")
                .build();

        // Setup mock product response from product-service
        mockProductDto = ProductDto.builder()
                .productId(1)
                .productTitle("Favourite Product")
                .imageUrl("http://test.com/favourite.jpg")
                .sku("FAV-SKU-001")
                .priceUnit(199.99)
                .quantity(50)
                .build();

        // Create and save a test favourite
        savedFavourite = Favourite.builder()
                .userId(1)
                .productId(1)
                .likeDate(LocalDateTime.now())
                .build();
        savedFavourite = favouriteRepository.save(savedFavourite);
    }

    /**
     * Integration Test 5: Verify favourite-service calls user-service to get user
     * details
     * Tests RestTemplate communication to USER_SERVICE_API_URL
     */
    @Test
    void testFindAllFavourites_CallsUserService() {
        // Arrange: Mock RestTemplate response from user-service
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + savedFavourite.getUserId()),
                eq(UserDto.class)))
                .thenReturn(mockUserDto);

        // Mock product-service response
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + savedFavourite.getProductId()),
                eq(ProductDto.class)))
                .thenReturn(mockProductDto);

        // Act: Call service method that triggers inter-service communication
        List<FavouriteDto> result = favouriteService.findAll();

        // Assert: Verify RestTemplate was called with correct user-service URL
        verify(restTemplate, atLeastOnce()).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + savedFavourite.getUserId()),
                eq(UserDto.class));

        // Assert: Verify result contains user information from external service
        assertNotNull(result);
        assertFalse(result.isEmpty());
        assertEquals(mockUserDto, result.get(0).getUserDto());
        assertEquals(savedFavourite.getUserId(), result.get(0).getUserId());
    }

    /**
     * Integration Test 6: Verify favourite-service calls product-service to get
     * product details
     * Tests RestTemplate communication to PRODUCT_SERVICE_API_URL
     */
    @Test
    void testFindFavouriteById_CallsProductService() {
        // Arrange: Create and save a new favourite for this test
        Favourite favourite = Favourite.builder()
                .userId(2)
                .productId(2)
                .likeDate(LocalDateTime.now())
                .build();
        Favourite saved = favouriteRepository.save(favourite);

        // Create composite key using the actual saved values
        FavouriteId favouriteId = new FavouriteId(saved.getUserId(),
                saved.getProductId(), saved.getLikeDate());

        // Mock product-service response
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + saved.getProductId()),
                eq(ProductDto.class)))
                .thenReturn(mockProductDto);

        // Mock user-service response
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + saved.getUserId()),
                eq(UserDto.class)))
                .thenReturn(mockUserDto);

        // Act: Call service method that triggers inter-service communication
        FavouriteDto result = favouriteService.findById(favouriteId);

        // Assert: Verify RestTemplate was called with correct product-service URL
        verify(restTemplate, times(1)).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + saved.getProductId()),
                eq(ProductDto.class));

        // Assert: Verify result contains product information from external service
        assertNotNull(result);
        assertNotNull(result.getProductDto());
        assertEquals(mockProductDto.getProductId(), result.getProductDto().getProductId());
        assertEquals(mockProductDto.getProductTitle(), result.getProductDto().getProductTitle());
        assertEquals(mockProductDto.getPriceUnit(), result.getProductDto().getPriceUnit());
    }

    /**
     * Integration Test 7: Verify favourite-service calls both user-service AND
     * product-service
     * Tests multiple RestTemplate calls in single operation
     */
    @Test
    void testFindFavouriteById_CallsMultipleServices() {
        // Arrange: Create and save a new favourite for this test
        Favourite favourite = Favourite.builder()
                .userId(3)
                .productId(3)
                .likeDate(LocalDateTime.now())
                .build();
        Favourite saved = favouriteRepository.save(favourite);

        // Create composite key using the actual saved values
        FavouriteId favouriteId = new FavouriteId(saved.getUserId(),
                saved.getProductId(), saved.getLikeDate());

        // Mock both service responses
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + saved.getUserId()),
                eq(UserDto.class)))
                .thenReturn(mockUserDto);

        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + saved.getProductId()),
                eq(ProductDto.class)))
                .thenReturn(mockProductDto);

        // Act: Call service method that triggers multiple inter-service communications
        FavouriteDto result = favouriteService.findById(favouriteId);

        // Assert: Verify both RestTemplate calls were made
        verify(restTemplate, times(1)).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + saved.getUserId()),
                eq(UserDto.class));

        verify(restTemplate, times(1)).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + saved.getProductId()),
                eq(ProductDto.class));

        // Assert: Verify result contains data from both external services
        assertNotNull(result);
        assertNotNull(result.getUserDto());
        assertNotNull(result.getProductDto());
        assertEquals(mockUserDto.getUserId(), result.getUserDto().getUserId());
        assertEquals(mockProductDto.getProductId(), result.getProductDto().getProductId());
    }
}
