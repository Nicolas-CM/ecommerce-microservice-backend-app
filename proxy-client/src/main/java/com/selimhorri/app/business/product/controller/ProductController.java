package com.selimhorri.app.business.product.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.selimhorri.app.business.product.model.ProductDto;
import com.selimhorri.app.business.product.model.response.ProductProductServiceCollectionDtoResponse;
import com.selimhorri.app.business.product.service.ProductClientService;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/products")
@Slf4j
@RequiredArgsConstructor
public class ProductController {

	private final ProductClientService productClientService;

	@GetMapping
	@Bulkhead(name = "productServiceBulkhead", fallbackMethod = "findAllFallback")
	public ResponseEntity<ProductProductServiceCollectionDtoResponse> findAll() {
		log.info("** Proxy Client: Fetching all products with Bulkhead protection **");
		return ResponseEntity.ok(this.productClientService.findAll().getBody());
	}

	@GetMapping("/{productId}")
	@Bulkhead(name = "productServiceBulkhead", fallbackMethod = "findByIdFallback")
	public ResponseEntity<ProductDto> findById(@PathVariable("productId") final String productId) {
		log.info("** Proxy Client: Fetching product {} with Bulkhead protection **", productId);
		return ResponseEntity.ok(this.productClientService.findById(productId).getBody());
	}

	public ResponseEntity<ProductProductServiceCollectionDtoResponse> findAllFallback(Throwable t) {
		log.error("!! Bulkhead Full: No se pueden procesar más peticiones de productos !! Error: {}", t.getMessage());
		return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
	}

	public ResponseEntity<ProductDto> findByIdFallback(String productId, Throwable t) {
		log.error("!! Bulkhead Full: No se puede obtener el producto {} !!", productId);
		return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
	}

	@PostMapping
	public ResponseEntity<ProductDto> save(@RequestBody final ProductDto productDto) {
		return ResponseEntity.ok(this.productClientService.save(productDto).getBody());
	}

	@PutMapping
	public ResponseEntity<ProductDto> update(@RequestBody final ProductDto productDto) {
		return ResponseEntity.ok(this.productClientService.update(productDto).getBody());
	}

	@PutMapping("/{productId}")
	public ResponseEntity<ProductDto> update(@PathVariable("productId") final String productId,
			@RequestBody final ProductDto productDto) {
		return ResponseEntity.ok(this.productClientService.update(productId, productDto).getBody());
	}

	@DeleteMapping("/{productId}")
	public ResponseEntity<Boolean> deleteById(@PathVariable("productId") final String productId) {
		return ResponseEntity.ok(this.productClientService.deleteById(productId).getBody());
	}

}
