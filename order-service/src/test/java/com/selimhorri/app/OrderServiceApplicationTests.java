package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Cart;
import com.selimhorri.app.domain.Order;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.repository.OrderRepository;
import com.selimhorri.app.service.impl.OrderServiceImpl;

@ExtendWith(MockitoExtension.class)
class OrderServiceApplicationTests {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private Order order;
    private OrderDto orderDto;
    private CartDto cartDto;
    private Cart cart;

    @BeforeEach
    void setUp() {
        LocalDateTime now = LocalDateTime.now();

        // Setup Cart entity
        cart = Cart.builder()
                .cartId(1)
                .build();

        // Setup CartDto
        cartDto = CartDto.builder()
                .cartId(1)
                .build();

        // Setup Order entity
        order = Order.builder()
                .orderId(1)
                .orderDate(now)
                .orderDesc("Test order")
                .orderFee(50.0)
                .cart(cart)
                .build();

        // Setup OrderDto
        orderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(now)
                .orderDesc("Test order")
                .orderFee(50.0)
                .cartDto(cartDto)
                .build();
    }

    /**
     * Test 1: Validate that saving an order creates it with correct order fee
     */
    @Test
    void testSaveOrder_Success() {
        // Arrange
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        // Act
        OrderDto result = orderService.save(orderDto);

        // Assert
        assertNotNull(result);
        assertEquals("Test order", result.getOrderDesc());
        assertEquals(50.0, result.getOrderFee());
        verify(orderRepository, times(1)).save(any(Order.class));
    }

    /**
     * Test 2: Validate that finding an order by ID returns correct order
     */
    @Test
    void testFindById_OrderExists() {
        // Arrange
        when(orderRepository.findById(anyInt())).thenReturn(Optional.of(order));

        // Act
        OrderDto result = orderService.findById(1);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getOrderId());
        assertEquals("Test order", result.getOrderDesc());
        verify(orderRepository, times(1)).findById(1);
    }

    /**
     * Test 3: Validate that updating an order changes order fee correctly
     */
    @Test
    void testUpdateOrder_FeeChanged() {
        // Arrange
        Order updatedOrder = Order.builder()
                .orderId(1)
                .orderDate(order.getOrderDate())
                .orderDesc("Test order")
                .orderFee(75.0)
                .cart(cart)
                .build();

        when(orderRepository.save(any(Order.class))).thenReturn(updatedOrder);

        OrderDto updatedOrderDto = OrderDto.builder()
                .orderId(1)
                .orderDate(order.getOrderDate())
                .orderDesc("Test order")
                .orderFee(75.0)
                .cartDto(cartDto)
                .build();

        // Act
        OrderDto result = orderService.update(updatedOrderDto);

        // Assert
        assertNotNull(result);
        assertEquals(75.0, result.getOrderFee());
        assertEquals("Test order", result.getOrderDesc());
        verify(orderRepository, times(1)).save(any(Order.class));
    }

}
