package com.selimhorri.app.config.filter;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.selimhorri.app.jwt.service.JwtService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
@RequiredArgsConstructor
public class JwtRequestFilter extends OncePerRequestFilter {

	private final UserDetailsService userDetailsService;
	private final JwtService jwtService;

	// ✅ Rutas que NO requieren JWT
	private static final List<String> PUBLIC_PATHS = Arrays.asList(
			"/api/authenticate",
			"/api/categories",
			"/api/products",
			"/actuator/health",
			"/actuator/info");

	@Override
	protected void doFilterInternal(final HttpServletRequest request, final HttpServletResponse response,
			final FilterChain filterChain)
			throws ServletException, IOException {

		final String requestURI = request.getRequestURI();
		final String method = request.getMethod();

		// ✅ Permitir rutas públicas sin JWT
		if (isPublicPath(requestURI, method)) {
			log.info("**Public path accessed: {} - No JWT required**", requestURI);
			filterChain.doFilter(request, response);
			return;
		}

		log.info("**JwtRequestFilter, validating JWT token for: {}**", requestURI);

		final var authorizationHeader = request.getHeader("Authorization");

		String username = null;
		String jwt = null;

		if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
			jwt = authorizationHeader.substring(7);
			username = jwtService.extractUsername(jwt);
		}

		if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {

			final UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);

			if (this.jwtService.validateToken(jwt, userDetails)) {
				final UsernamePasswordAuthenticationToken usernamePasswordAuthenticationToken = new UsernamePasswordAuthenticationToken(
						userDetails, null, userDetails.getAuthorities());
				usernamePasswordAuthenticationToken
						.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
				SecurityContextHolder.getContext().setAuthentication(usernamePasswordAuthenticationToken);
				log.info("**JWT validated successfully for user: {}**", username);
			}
		}

		filterChain.doFilter(request, response);
	}

	// ✅ Verificar si la ruta es pública
	private boolean isPublicPath(String uri, String method) {
		// POST /api/users (registro) es público
		if ("POST".equals(method) && uri.contains("/api/users")) {
			return true;
		}

		// GET en categorías y productos es público
		if ("GET".equals(method) && (uri.contains("/api/categories") || uri.contains("/api/products"))) {
			return true;
		}

		// Rutas de autenticación y actuator health
		return PUBLIC_PATHS.stream().anyMatch(uri::contains);
	}

}
