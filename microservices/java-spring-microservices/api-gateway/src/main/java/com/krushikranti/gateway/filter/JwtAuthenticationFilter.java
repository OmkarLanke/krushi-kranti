package com.krushikranti.gateway.filter;

import com.krushikranti.gateway.config.GatewayJwtProperties;
import com.krushikranti.gateway.service.JwksService;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Global JWT Authentication Filter.
 * Validates JWT tokens using JWKS from Auth Service.
 * Extracts user information and adds headers for downstream services.
 */
@Component
@Slf4j
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    private final GatewayJwtProperties jwtProperties;
    private final JwksService jwksService;

    @Autowired
    public JwtAuthenticationFilter(GatewayJwtProperties jwtProperties, JwksService jwksService) {
        this.jwtProperties = jwtProperties;
        this.jwksService = jwksService;
    }

    @PostConstruct
    public void init() {
        log.info("JWT Filter initialized with skip paths: {}", jwtProperties.getSkipPaths());
        log.info("JWKS URI: {}", jwtProperties.getJwksUri());
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getURI().getPath();

        // Skip JWT validation for public endpoints
        if (!jwtProperties.isEnabled() || shouldSkipPath(path)) {
            log.debug("Skipping JWT validation for path: {}", path);
            return chain.filter(exchange);
        }

        String token = extractToken(request);
        
        if (!StringUtils.hasText(token)) {
            log.warn("Missing JWT token for path: {}", path);
            return handleUnauthorized(exchange, "Missing authentication token");
        }

        // Validate token using JWKS
        return jwksService.validateToken(token)
                .flatMap(result -> {
                    if (!result.valid()) {
                        log.warn("Token validation failed for path {}: {}", path, result.errorMessage());
                        return handleUnauthorized(exchange, result.errorMessage());
                    }

                    log.debug("Token validated for user: {} with roles: {}", result.username(), result.roles());

                    // Add user information headers for downstream services
                    ServerHttpRequest modifiedRequest = request.mutate()
                            .header("X-User-Id", result.userId() != null ? result.userId() : "")
                            .header("X-User-Roles", result.roles() != null ? String.join(",", result.roles()) : "")
                            .header("X-Username", result.username() != null ? result.username() : "")
                            .header("Authorization", "Bearer " + token)
                            .build();

                    return chain.filter(exchange.mutate().request(modifiedRequest).build());
                })
                .onErrorResume(e -> {
                    log.error("Error during token validation: {}", e.getMessage());
                    return handleUnauthorized(exchange, "Token validation error");
                });
    }

    private boolean shouldSkipPath(String path) {
        List<String> skipPaths = jwtProperties.getSkipPaths();
        boolean shouldSkip = skipPaths.stream().anyMatch(skipPath -> path.startsWith(skipPath));
        if (shouldSkip) {
            log.debug("Path {} matches skip pattern", path);
        } else {
            log.debug("Path {} requires JWT validation. Skip paths: {}", path, skipPaths);
        }
        return shouldSkip;
    }

    private String extractToken(ServerHttpRequest request) {
        String bearerToken = request.getHeaders().getFirst("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    private Mono<Void> handleUnauthorized(ServerWebExchange exchange, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        String errorJson = String.format(
                "{\"error\":\"Unauthorized\",\"status\":401,\"message\":\"%s\"}",
                message != null ? message : "Authentication required"
        );
        
        DataBuffer buffer = response.bufferFactory()
                .wrap(errorJson.getBytes(StandardCharsets.UTF_8));
        
        return response.writeWith(Mono.just(buffer));
    }

    @Override
    public int getOrder() {
        return -100;
    }
}
