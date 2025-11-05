package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.domain.PaymentStatus;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.repository.PaymentRepository;
import com.selimhorri.app.service.impl.PaymentServiceImpl;

@ExtendWith(MockitoExtension.class)
class PaymentServiceApplicationTests {

    @Mock
    private PaymentRepository paymentRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private PaymentServiceImpl paymentService;

    private Payment payment;
    private PaymentDto paymentDto;
    private OrderDto orderDto;

    @BeforeEach
    void setUp() {
        // Setup OrderDto
        orderDto = OrderDto.builder()
                .orderId(1)
                .build();

        // Setup Payment entity
        payment = Payment.builder()
                .paymentId(1)
                .isPayed(false)
                .paymentStatus(PaymentStatus.NOT_STARTED)
                .orderId(1)
                .build();

        // Setup PaymentDto
        paymentDto = PaymentDto.builder()
                .paymentId(1)
                .isPayed(false)
                .paymentStatus(PaymentStatus.NOT_STARTED)
                .orderDto(orderDto)
                .build();
    }

    /**
     * Test 1: Validate that saving a payment creates it with correct payment status
     */
    @Test
    void testSavePayment_Success() {
        // Arrange
        when(paymentRepository.save(any(Payment.class))).thenReturn(payment);

        // Act
        PaymentDto result = paymentService.save(paymentDto);

        // Assert
        assertNotNull(result);
        assertEquals(PaymentStatus.NOT_STARTED, result.getPaymentStatus());
        assertEquals(false, result.getIsPayed());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }

    /**
     * Test 2: Validate that finding a payment by ID retrieves order information via
     * RestTemplate
     */
    @Test
    void testFindById_FetchesOrderInformation() {
        // Arrange
        when(paymentRepository.findById(anyInt())).thenReturn(Optional.of(payment));
        when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

        // Act
        PaymentDto result = paymentService.findById(1);

        // Assert
        assertNotNull(result);
        assertNotNull(result.getOrderDto());
        assertEquals(1, result.getOrderDto().getOrderId());
        verify(paymentRepository, times(1)).findById(1);
        verify(restTemplate, times(1)).getForObject(anyString(), eq(OrderDto.class));
    }

    /**
     * Test 3: Validate that updating a payment changes payment status correctly
     */
    @Test
    void testUpdatePayment_StatusChanged() {
        // Arrange
        Payment completedPayment = Payment.builder()
                .paymentId(1)
                .isPayed(true)
                .paymentStatus(PaymentStatus.COMPLETED)
                .orderId(1)
                .build();

        when(paymentRepository.save(any(Payment.class))).thenReturn(completedPayment);

        PaymentDto updatedPaymentDto = PaymentDto.builder()
                .paymentId(1)
                .isPayed(true)
                .paymentStatus(PaymentStatus.COMPLETED)
                .orderDto(orderDto)
                .build();

        // Act
        PaymentDto result = paymentService.update(updatedPaymentDto);

        // Assert
        assertNotNull(result);
        assertEquals(true, result.getIsPayed());
        assertEquals(PaymentStatus.COMPLETED, result.getPaymentStatus());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }

}
