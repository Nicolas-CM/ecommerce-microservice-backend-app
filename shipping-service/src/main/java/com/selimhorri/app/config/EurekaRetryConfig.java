package com.selimhorri.app.config;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.netflix.eureka.EurekaClientConfigBean;
import org.springframework.context.annotation.Configuration;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;

import com.netflix.discovery.EurekaClient;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Configuration
@Slf4j
@RequiredArgsConstructor
public class EurekaRetryConfig {
	
	private final EurekaClient eurekaClient;
	private final EurekaClientConfigBean clientConfig;
	
	@Value("${spring.application.name}")
	private String applicationName;
	
	@PostConstruct
	@Retryable(
		value = Exception.class,
		maxAttempts = 50,
		backoff = @Backoff(delay = 10000)
	)
	public void registerWithEureka() {
		try {
			log.info("*** {} intentando registrarse en Eureka: {} ***", 
					applicationName, 
					clientConfig.getServiceUrl());
			
			eurekaClient.getApplications();
			
			log.info("*** {} registrado exitosamente en Eureka ***", applicationName);
		} catch (Exception e) {
			log.warn("*** Eureka no disponible aún, reintentando en 10 segundos... ***");
			throw e;
		}
	}
	
	@Recover
	public void recover(Exception e) {
		log.error("*** {} no pudo registrarse en Eureka después de múltiples intentos. " +
				"El servicio seguirá intentando en segundo plano. ***", applicationName);
	}
	
}
