package com.selimhorri.app.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.selimhorri.app.business.user.model.RoleBasedAuthority;
import com.selimhorri.app.config.filter.JwtRequestFilter;

import lombok.RequiredArgsConstructor;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig extends WebSecurityConfigurerAdapter {

	private final UserDetailsService userDetailsService;
	private final PasswordEncoder passwordEncoder;
	private final JwtRequestFilter jwtRequestFilter;

	@Override
	protected void configure(final AuthenticationManagerBuilder auth) throws Exception {
		auth.userDetailsService(this.userDetailsService)
				.passwordEncoder(this.passwordEncoder);
	}

	@Override
	protected void configure(final HttpSecurity http) throws Exception {
		http.cors().disable()
				.csrf().disable()
				.authorizeRequests()
				// ✅ Endpoints públicos (sin autenticación)
				.antMatchers(HttpMethod.OPTIONS, "/**").permitAll()
				.antMatchers("/", "index", "**/css/**", "**/js/**").permitAll()

				// ✅ Autenticación - PÚBLICO para poder hacer login
				.antMatchers("/api/authenticate/**").permitAll()

				// ✅ Endpoints públicos del negocio
				.antMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
				.antMatchers(HttpMethod.GET, "/api/products/**").permitAll()

				// ✅ Registro de usuarios - PÚBLICO
				.antMatchers(HttpMethod.POST, "/api/users").permitAll()

				// ✅ Actuator - health público, resto requiere ADMIN
				.antMatchers("/actuator/health/**", "/actuator/info/**").permitAll()
				.antMatchers("/actuator/**")
				.hasRole(RoleBasedAuthority.ROLE_ADMIN.getRole())

				// ✅ Todas las demás rutas de API requieren autenticación
				.antMatchers("/api/**")
				.hasAnyRole(RoleBasedAuthority.ROLE_USER.getRole(),
						RoleBasedAuthority.ROLE_ADMIN.getRole())

				// ✅ Cualquier otra petición debe estar autenticada
				.anyRequest().authenticated()
				.and()
				.headers()
				.frameOptions()
				.sameOrigin()
				.and()
				.sessionManagement()
				.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
				.and()
				// ✅ Filtro JWT ANTES de UsernamePasswordAuthenticationFilter
				.addFilterBefore(this.jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
	}

	@Bean
	@Override
	public AuthenticationManager authenticationManagerBean() throws Exception {
		return super.authenticationManagerBean();
	}

}
