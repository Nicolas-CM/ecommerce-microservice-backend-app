package com.selimhorri.app.business.auth.controller;

import javax.validation.Valid;
import javax.validation.constraints.NotNull;

import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.selimhorri.app.business.auth.model.request.AuthenticationRequest;
import com.selimhorri.app.business.auth.model.request.PasswordVerificationRequest;
import com.selimhorri.app.business.auth.model.response.AuthenticationResponse;
import com.selimhorri.app.business.auth.service.AuthenticationService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/authenticate")
@Slf4j
@RequiredArgsConstructor
public class AuthenticationController {

	private final AuthenticationService authenticationService;
	private final PasswordEncoder passwordEncoder;

	@PostMapping
	public ResponseEntity<AuthenticationResponse> authenticate(
			@RequestBody @NotNull(message = "") @Valid final AuthenticationRequest authenticationRequest) {
		log.info("**Authentication controller, proceed with the request*\n");
		return ResponseEntity.ok(this.authenticationService.authenticate(authenticationRequest));
	}

	@GetMapping("/jwt/{jwt}")
	public ResponseEntity<Boolean> authenticate(@PathVariable("jwt") final String jwt) {
		log.info("**Authentication controller, proceed with the request*\n");
		return ResponseEntity.ok(this.authenticationService.authenticate(jwt));
	}

	@GetMapping("/status")
	public ResponseEntity<String> getStatus() {
		log.info("**Authentication controller, status check*\n");
		return ResponseEntity.ok("Código actualizado correctamente, aquí en dev :)");
	}

	@GetMapping("/hash/{password}")
	public ResponseEntity<String> getPasswordHash(@PathVariable("password") final String password) {
		log.info("**Authentication controller, generating password hash*\n");
		return ResponseEntity.ok(this.passwordEncoder.encode(password));
	}

	@PostMapping("/verify")
	public ResponseEntity<Boolean> verifyPassword(@RequestBody @Valid final PasswordVerificationRequest request) {
		log.info("**Authentication controller, verifying password: {} against hash*\n", request.getPassword());
		return ResponseEntity.ok(this.passwordEncoder.matches(request.getPassword(), request.getHash()));
	}

}
