package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Category;
import com.selimhorri.app.domain.Product;
import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.repository.ProductRepository;
import com.selimhorri.app.service.impl.ProductServiceImpl;

@ExtendWith(MockitoExtension.class)
class ProductServiceApplicationTests {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private ProductDto testProductDto;
    private Product testProduct;
    private Category testCategory;

    @BeforeEach
    void setUp() {
        // Preparar datos de prueba
        testCategory = Category.builder()
                .categoryId(1)
                .categoryTitle("Electronics")
                .imageUrl("https://example.com/electronics.jpg")
                .build();

        CategoryDto categoryDto = CategoryDto.builder()
                .categoryId(1)
                .categoryTitle("Electronics")
                .imageUrl("https://example.com/electronics.jpg")
                .build();

        testProductDto = ProductDto.builder()
                .productTitle("Laptop Dell XPS 15")
                .imageUrl("https://example.com/laptop.jpg")
                .sku("DELL-XPS-15-2024")
                .priceUnit(1500.00)
                .quantity(50)
                .categoryDto(categoryDto)
                .build();

        testProduct = Product.builder()
                .productId(1)
                .productTitle("Laptop Dell XPS 15")
                .imageUrl("https://example.com/laptop.jpg")
                .sku("DELL-XPS-15-2024")
                .priceUnit(1500.00)
                .quantity(50)
                .category(testCategory)
                .build();
    }

    /**
     * PRUEBA UNITARIA 1: Verificar que se puede crear un producto correctamente
     * 
     * Esta prueba valida:
     * - El servicio recibe un ProductDto y lo convierte a entidad
     * - Se guarda correctamente en el repositorio con todos sus atributos
     * - Se retorna el ProductDto con la información correcta
     * - Se asocia correctamente con su categoría
     */
    @Test
    void testSaveProduct_Success() {
        // Given
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // When
        ProductDto result = productService.save(testProductDto);

        // Then
        assertNotNull(result, "El resultado no debe ser null");
        assertEquals("Laptop Dell XPS 15", result.getProductTitle());
        assertEquals("DELL-XPS-15-2024", result.getSku());
        assertEquals(1500.00, result.getPriceUnit());
        assertEquals(50, result.getQuantity());
        assertNotNull(result.getCategoryDto());
        assertEquals(1, result.getCategoryDto().getCategoryId());

        verify(productRepository, times(1)).save(any(Product.class));
    }

    /**
     * PRUEBA UNITARIA 2: Verificar búsqueda de producto por ID
     * 
     * Esta prueba valida:
     * - El servicio puede buscar un producto por su ID
     * - Se retorna el ProductDto correcto cuando existe
     * - Se lanza ProductNotFoundException cuando no existe
     */
    @Test
    void testFindById_ProductExists() {
        // Given
        when(productRepository.findById(1)).thenReturn(Optional.of(testProduct));

        // When
        ProductDto result = productService.findById(1);

        // Then
        assertNotNull(result, "El resultado no debe ser null");
        assertEquals(1, result.getProductId());
        assertEquals("Laptop Dell XPS 15", result.getProductTitle());
        assertEquals(1500.00, result.getPriceUnit());
        assertEquals(50, result.getQuantity());

        verify(productRepository, times(1)).findById(1);
    }

    @Test
    void testFindById_ProductNotFound_ThrowsException() {
        // Given
        when(productRepository.findById(999)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(Exception.class, () -> {
            productService.findById(999);
        }, "Debe lanzar excepción cuando el producto no existe");

        verify(productRepository, times(1)).findById(999);
    }

    /**
     * PRUEBA UNITARIA 3: Verificar actualización de stock de producto
     * 
     * Esta prueba valida:
     * - El servicio puede actualizar la información de un producto
     * - Los cambios en cantidad (stock) se persisten correctamente
     * - Se mantienen los demás atributos del producto
     */
    @Test
    void testUpdateProduct_StockQuantityChanged() {
        // Given: Producto con stock actualizado
        ProductDto updateDto = ProductDto.builder()
                .productId(1)
                .productTitle("Laptop Dell XPS 15")
                .imageUrl("https://example.com/laptop.jpg")
                .sku("DELL-XPS-15-2024")
                .priceUnit(1500.00)
                .quantity(25) // Stock reducido de 50 a 25
                .categoryDto(CategoryDto.builder().categoryId(1).build())
                .build();

        Product updatedProduct = Product.builder()
                .productId(1)
                .productTitle("Laptop Dell XPS 15")
                .imageUrl("https://example.com/laptop.jpg")
                .sku("DELL-XPS-15-2024")
                .priceUnit(1500.00)
                .quantity(25)
                .category(testCategory)
                .build();

        when(productRepository.save(any(Product.class))).thenReturn(updatedProduct);

        // When
        ProductDto result = productService.update(updateDto);

        // Then
        assertNotNull(result, "El resultado no debe ser null");
        assertEquals(1, result.getProductId());
        assertEquals("Laptop Dell XPS 15", result.getProductTitle());
        assertEquals(1500.00, result.getPriceUnit());
        assertEquals(25, result.getQuantity(), "La cantidad debe actualizarse a 25");

        verify(productRepository, times(1)).save(any(Product.class));
    }

    /**
     * PRUEBA ADICIONAL: Verificar eliminación de producto
     */
    @Test
    void testDeleteProduct_Success() {
        // Given
        when(productRepository.findById(1)).thenReturn(Optional.of(testProduct));
        doNothing().when(productRepository).delete(any(Product.class));

        // When
        productService.deleteById(1);

        // Then
        verify(productRepository, times(1)).findById(1);
        verify(productRepository, times(1)).delete(any(Product.class));
    }

}
