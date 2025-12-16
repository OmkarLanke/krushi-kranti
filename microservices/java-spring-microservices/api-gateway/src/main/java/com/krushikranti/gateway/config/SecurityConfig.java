package com.krushikranti.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeExchange(exchanges -> exchanges
                        .pathMatchers("/auth/login", "/auth/register", "/auth/verify-otp", "/auth/request-login-otp", "/.well-known/**", "/actuator/**")
                        .permitAll()
                        .anyExchange()
                        .permitAll() // Allow all for now - JWT validation handled in filter
                );
                // OAuth2 resource server will be configured when Auth Service is ready
                // JWT validation is currently handled in JwtAuthenticationFilter

        return http.build();
    }
}

