package com.selimhorri.app.business.auth.model.request;

import javax.validation.constraints.NotBlank;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PasswordVerificationRequest {
	
	@NotBlank(message = "Password is required")
	private String password;
	
	@NotBlank(message = "Hash is required")
	private String hash;
	
}
