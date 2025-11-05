package com.selimhorri.app;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.repository.OrderItemRepository;
import com.selimhorri.app.service.impl.OrderItemServiceImpl;

@ExtendWith(MockitoExtension.class)
class ShippingServiceApplicationTests {

    @Mock
    private OrderItemRepository orderItemRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private OrderItemServiceImpl orderItemService;

    private OrderItemDto testOrderItemDto;
    private OrderItem testOrderItem;
    private OrderItemId testOrderItemId;

    @BeforeEach
    void setUp() {
        // Preparar datos de prueba
        testOrderItemId = new OrderItemId(1, 1); // productId=1, orderId=1

        ProductDto productDto = ProductDto.builder()
                .productId(1)
                .build();

        OrderDto orderDto = OrderDto.builder()
                .orderId(1)
                .build();

        testOrderItemDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .productDto(productDto)
                .orderDto(orderDto)
                .build();

        testOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .build();
    }

    /**
     * PRUEBA UNITARIA 1: Verificar que se puede crear un OrderItem correctamente
     * 
     * Esta prueba valida:
     * - El servicio recibe un OrderItemDto y lo convierte a entidad
     * - Se guarda correctamente en el repositorio
     * - Se retorna el OrderItemDto con los datos correctos
     */
    @Test
    void testSaveOrderItem_Success() {
        // Given
        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(testOrderItem);

        // When
        OrderItemDto result = orderItemService.save(testOrderItemDto);

        // Then
        assertNotNull(result, "El resultado no debe ser null");
        assertEquals(1, result.getProductId());
        assertEquals(1, result.getOrderId());
        assertEquals(5, result.getOrderedQuantity());

        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    /**
     * PRUEBA UNITARIA 2: Verificar actualización de cantidad de productos en un
     * OrderItem
     * 
     * Esta prueba valida:
     * - El servicio puede actualizar la cantidad de productos en una orden
     * - Los cambios se persisten correctamente
     * - Los IDs de producto y orden se mantienen
     */
    @Test
    void testUpdateOrderItem_QuantityChanged() {
        // Given: OrderItem con cantidad actualizada
        OrderItemDto updateDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(10) // Cambio de 5 a 10
                .build();

        OrderItem updatedOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(10)
                .build();

        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(updatedOrderItem);

        // When
        OrderItemDto result = orderItemService.update(updateDto);

        // Then
        assertNotNull(result, "El resultado no debe ser null");
        assertEquals(1, result.getProductId());
        assertEquals(1, result.getOrderId());
        assertEquals(10, result.getOrderedQuantity(), "La cantidad debe actualizarse a 10");

        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    /**
     * PRUEBA UNITARIA 3: Verificar eliminación de un OrderItem por su ID compuesto
     * 
     * Esta prueba valida:
     * - El servicio puede eliminar un OrderItem usando su clave compuesta
     * - Se invoca correctamente el método deleteById del repositorio
     * - No se producen errores durante la eliminación
     */
    @Test
    void testDeleteOrderItem_Success() {
        // Given
        doNothing().when(orderItemRepository).deleteById(testOrderItemId);

        // When
        orderItemService.deleteById(testOrderItemId);

        // Then
        verify(orderItemRepository, times(1)).deleteById(testOrderItemId);
    }

}
