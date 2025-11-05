package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.domain.id.FavouriteId;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.repository.FavouriteRepository;
import com.selimhorri.app.service.impl.FavouriteServiceImpl;

@ExtendWith(MockitoExtension.class)
class FavouriteServiceApplicationTests {

    @Mock
    private FavouriteRepository favouriteRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private FavouriteServiceImpl favouriteService;

    private Favourite favourite;
    private FavouriteDto favouriteDto;
    private FavouriteId favouriteId;
    private UserDto userDto;
    private ProductDto productDto;

    @BeforeEach
    void setUp() {
        LocalDateTime now = LocalDateTime.now();

        // Setup FavouriteId (composite key with userId, productId, and likeDate)
        favouriteId = new FavouriteId(1, 1, now);

        // Setup UserDto
        userDto = UserDto.builder()
                .userId(1)
                .firstName("Test")
                .lastName("User")
                .email("test@example.com")
                .build();

        // Setup ProductDto
        productDto = ProductDto.builder()
                .productId(1)
                .productTitle("Test Product")
                .build();

        // Setup Favourite entity
        favourite = Favourite.builder()
                .userId(1)
                .productId(1)
                .likeDate(now)
                .build();

        // Setup FavouriteDto
        favouriteDto = FavouriteDto.builder()
                .userId(1)
                .productId(1)
                .likeDate(now)
                .userDto(userDto)
                .productDto(productDto)
                .build();
    }

    /**
     * Test 1: Validate that saving a favourite creates it with correct like date
     */
    @Test
    void testSaveFavourite_Success() {
        // Arrange
        when(favouriteRepository.save(any(Favourite.class))).thenReturn(favourite);

        // Act
        FavouriteDto result = favouriteService.save(favouriteDto);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getUserId());
        assertEquals(1, result.getProductId());
        assertNotNull(result.getLikeDate());
        verify(favouriteRepository, times(1)).save(any(Favourite.class));
    }

    /**
     * Test 2: Validate that finding a favourite by ID fetches user and product
     * information via RestTemplate
     */
    @Test
    void testFindById_FetchesUserAndProductInformation() {
        // Arrange
        when(favouriteRepository.findById(any(FavouriteId.class))).thenReturn(Optional.of(favourite));
        when(restTemplate.getForObject(anyString(), eq(UserDto.class))).thenReturn(userDto);
        when(restTemplate.getForObject(anyString(), eq(ProductDto.class))).thenReturn(productDto);

        // Act
        FavouriteDto result = favouriteService.findById(favouriteId);

        // Assert
        assertNotNull(result);
        assertNotNull(result.getUserDto());
        assertNotNull(result.getProductDto());
        assertEquals(1, result.getUserId());
        assertEquals(1, result.getProductId());
        assertEquals("Test", result.getUserDto().getFirstName());
        assertEquals("Test Product", result.getProductDto().getProductTitle());
        verify(favouriteRepository, times(1)).findById(any(FavouriteId.class));
        verify(restTemplate, times(1)).getForObject(anyString(), eq(UserDto.class));
        verify(restTemplate, times(1)).getForObject(anyString(), eq(ProductDto.class));
    }

    /**
     * Test 3: Validate that updating a favourite changes the like date correctly
     */
    @Test
    void testUpdateFavourite_LikeDateChanged() {
        // Arrange
        LocalDateTime newLikeDate = LocalDateTime.now().plusDays(1);
        Favourite updatedFavourite = Favourite.builder()
                .userId(1)
                .productId(1)
                .likeDate(newLikeDate)
                .build();

        when(favouriteRepository.save(any(Favourite.class))).thenReturn(updatedFavourite);

        FavouriteDto updatedFavouriteDto = FavouriteDto.builder()
                .userId(1)
                .productId(1)
                .likeDate(newLikeDate)
                .userDto(userDto)
                .productDto(productDto)
                .build();

        // Act
        FavouriteDto result = favouriteService.update(updatedFavouriteDto);

        // Assert
        assertNotNull(result);
        assertEquals(newLikeDate, result.getLikeDate());
        assertEquals(1, result.getUserId());
        assertEquals(1, result.getProductId());
        verify(favouriteRepository, times(1)).save(any(Favourite.class));
    }

}
