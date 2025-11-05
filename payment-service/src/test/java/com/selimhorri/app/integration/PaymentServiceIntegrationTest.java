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
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.domain.PaymentStatus;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.repository.PaymentRepository;
import com.selimhorri.app.service.PaymentService;

/**
 * Integration tests for Payment Service communication with Order service
 * Validates RestTemplate calls to order-service for order information
 */
@SpringBootTest
class PaymentServiceIntegrationTest {

    @Autowired
    private PaymentService paymentService;

    @Autowired
    private PaymentRepository paymentRepository;

    @MockBean
    private RestTemplate restTemplate;

    private OrderDto mockOrderDto;
    private Payment savedPayment;

    @BeforeEach
    void setUp() {
        // Clear test data
        paymentRepository.deleteAll();

        // Setup mock order response from order-service
        mockOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(LocalDateTime.now())
                .orderDesc("Test Order for Payment")
                .orderFee(150.0)
                .build();

        // Create and save a test payment
        savedPayment = Payment.builder()
                .orderId(1)
                .isPayed(false)
                .paymentStatus(PaymentStatus.IN_PROGRESS)
                .build();
        savedPayment = paymentRepository.save(savedPayment);
    }

    /**
     * Integration Test 3: Verify payment-service calls order-service to get order
     * details
     * Tests RestTemplate communication to ORDER_SERVICE_API_URL
     */
    @Test
    void testFindAllPayments_CallsOrderService() {
        // Arrange: Mock RestTemplate response from order-service
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + savedPayment.getOrderId()),
                eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // Act: Call service method that triggers inter-service communication
        List<PaymentDto> result = paymentService.findAll();

        // Assert: Verify RestTemplate was called with correct order-service URL
        verify(restTemplate, times(1)).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + savedPayment.getOrderId()),
                eq(OrderDto.class));

        // Assert: Verify result contains order information from external service
        assertNotNull(result);
        assertFalse(result.isEmpty());
        assertEquals(mockOrderDto, result.get(0).getOrderDto());
        assertEquals(savedPayment.getPaymentId(), result.get(0).getPaymentId());
    }

    /**
     * Integration Test 4: Verify payment-service fetches order details by payment
     * ID
     * Tests that order information is correctly populated from order-service
     */
    @Test
    void testFindPaymentById_FetchesOrderInformation() {
        // Arrange: Mock order-service response
        when(restTemplate.getForObject(
                eq(AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + savedPayment.getOrderId()),
                eq(OrderDto.class)))
                .thenReturn(mockOrderDto);

        // Act: Call service method that triggers inter-service communication
        PaymentDto result = paymentService.findById(savedPayment.getPaymentId());

        // Assert: Verify RestTemplate was called
        verify(restTemplate, times(1)).getForObject(
                eq(AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + savedPayment.getOrderId()),
                eq(OrderDto.class));

        // Assert: Verify payment contains correct order data from order-service
        assertNotNull(result);
        assertEquals(savedPayment.getPaymentId(), result.getPaymentId());
        assertNotNull(result.getOrderDto());
        assertEquals(mockOrderDto.getOrderId(), result.getOrderDto().getOrderId());
        assertEquals(mockOrderDto.getOrderFee(), result.getOrderDto().getOrderFee());
    }
}
