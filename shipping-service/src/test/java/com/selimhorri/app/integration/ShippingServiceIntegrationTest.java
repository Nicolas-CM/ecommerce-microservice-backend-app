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
import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.repository.OrderItemRepository;
import com.selimhorri.app.service.OrderItemService;

/**
 * Integration tests for Shipping Service communication with Product and Order
 * services
 * Validates RestTemplate calls between microservices
 */
@SpringBootTest
@Transactional
class ShippingServiceIntegrationTest {

    @Autowired
    private OrderItemService orderItemService;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @MockBean
    private RestTemplate restTemplate;

    private ProductDto mockProductDto;
    private OrderDto mockOrderDto;

    @BeforeEach
    void setUp() {
        // Setup mock product response from product-service
        mockProductDto = ProductDto.builder()
                .productId(1)
                .productTitle("Test Product")
                .imageUrl("http://test.com/product.jpg")
                .sku("TEST-SKU-001")
                .priceUnit(99.99)
                .quantity(100)
                .build();

        // Setup mock order response from order-service
        mockOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order")
                .orderFee(15.0)
                .build();
    }

    /**
     * Integration Test 1: Verify shipping-service calls product-service to get
     * product details
     * Tests RestTemplate communication to PRODUCT_SERVICE_API_URL
     */
    @Test
    void testFindAllOrderItems_CallsProductService() {
        // Arrange: Create and save a test order item
        OrderItem orderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .build();
        orderItemRepository.save(orderItem);

        // Mock RestTemplate response from product-service
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/1"),
                eq(ProductDto.class)))
                .thenReturn(mockProductDto);

        // Mock order-service response
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/1"),
                eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // Act: Call service method that triggers inter-service communication
        List<OrderItemDto> result = orderItemService.findAll();

        // Assert: Verify RestTemplate was called with correct product-service URL
        verify(restTemplate, atLeastOnce()).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/1"),
                eq(ProductDto.class));

        // Assert: Verify result contains product information from external service
        assertNotNull(result);
        assertFalse(result.isEmpty());
        assertEquals(mockProductDto, result.get(0).getProductDto());
    }
}
