package com.krushikranti.gateway.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.krushikranti.gateway.config.GatewayJwtProperties;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.security.interfaces.RSAPublicKey;
import java.text.ParseException;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * JWKS Service for fetching and caching JSON Web Key Sets.
 * Used by API Gateway to validate JWT tokens from Auth Service.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class JwksService {

    private final GatewayJwtProperties jwtProperties;
    private final WebClient.Builder webClientBuilder;

    private Cache<String, JWKSet> jwksCache;
    private WebClient webClient;

    private static final String JWKS_CACHE_KEY = "jwks";
    private static final Duration CACHE_DURATION = Duration.ofMinutes(5);

    @PostConstruct
    public void init() {
        this.webClient = webClientBuilder.build();
        this.jwksCache = Caffeine.newBuilder()
                .expireAfterWrite(CACHE_DURATION.toMinutes(), TimeUnit.MINUTES)
                .maximumSize(10)
                .build();
        log.info("JWKS Service initialized. JWKS URI: {}", jwtProperties.getJwksUri());
    }

    /**
     * Fetch JWKS from Auth Service (with caching)
     */
    public Mono<JWKSet> getJwks() {
        JWKSet cachedJwks = jwksCache.getIfPresent(JWKS_CACHE_KEY);
        if (cachedJwks != null) {
            log.debug("Using cached JWKS");
            return Mono.just(cachedJwks);
        }

        log.info("Fetching JWKS from: {}", jwtProperties.getJwksUri());
        return webClient.get()
                .uri(jwtProperties.getJwksUri())
                .retrieve()
                .bodyToMono(String.class)
                .map(this::parseJwks)
                .doOnNext(jwkSet -> {
                    jwksCache.put(JWKS_CACHE_KEY, jwkSet);
                    log.info("JWKS cached. Keys count: {}", jwkSet.getKeys().size());
                })
                .doOnError(e -> log.error("Failed to fetch JWKS: {}", e.getMessage()));
    }

    /**
     * Validate a JWT token using JWKS
     */
    public Mono<TokenValidationResult> validateToken(String token) {
        return getJwks()
                .map(jwkSet -> validateTokenWithJwks(token, jwkSet))
                .onErrorReturn(new TokenValidationResult(false, null, null, null, "Failed to fetch JWKS"));
    }

    /**
     * Validate token with the provided JWKS
     */
    private TokenValidationResult validateTokenWithJwks(String token, JWKSet jwkSet) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            JWSHeader header = signedJWT.getHeader();
            
            // Get key ID from token header
            String keyId = header.getKeyID();
            if (keyId == null) {
                log.warn("Token has no key ID in header");
                return new TokenValidationResult(false, null, null, null, "Token has no key ID");
            }

            // Find the key in JWKS
            JWK jwk = jwkSet.getKeyByKeyId(keyId);
            if (jwk == null) {
                log.warn("Key ID {} not found in JWKS", keyId);
                return new TokenValidationResult(false, null, null, null, "Key not found in JWKS");
            }

            // Verify it's an RSA key
            if (!(jwk instanceof RSAKey)) {
                log.warn("Key {} is not an RSA key", keyId);
                return new TokenValidationResult(false, null, null, null, "Invalid key type");
            }

            RSAKey rsaKey = (RSAKey) jwk;
            RSAPublicKey publicKey = rsaKey.toRSAPublicKey();
            
            // Verify signature
            JWSVerifier verifier = new RSASSAVerifier(publicKey);
            if (!signedJWT.verify(verifier)) {
                log.warn("Token signature verification failed");
                return new TokenValidationResult(false, null, null, null, "Invalid signature");
            }

            // Get claims
            JWTClaimsSet claims = signedJWT.getJWTClaimsSet();
            
            // Verify expiration
            Date expirationTime = claims.getExpirationTime();
            if (expirationTime == null || expirationTime.before(Date.from(Instant.now()))) {
                log.warn("Token has expired");
                return new TokenValidationResult(false, null, null, null, "Token expired");
            }

            // Extract user information
            String userId = claims.getSubject();
            String username = (String) claims.getClaim("username");
            @SuppressWarnings("unchecked")
            List<String> roles = (List<String>) claims.getClaim("roles");

            log.debug("Token validated successfully for user: {}", username);
            return new TokenValidationResult(true, userId, username, roles, null);

        } catch (ParseException e) {
            log.error("Failed to parse JWT: {}", e.getMessage());
            return new TokenValidationResult(false, null, null, null, "Invalid token format");
        } catch (JOSEException e) {
            log.error("Failed to verify JWT: {}", e.getMessage());
            return new TokenValidationResult(false, null, null, null, "Verification failed");
        }
    }

    /**
     * Parse JWKS JSON string into JWKSet object
     */
    private JWKSet parseJwks(String jwksJson) {
        try {
            return JWKSet.parse(jwksJson);
        } catch (ParseException e) {
            log.error("Failed to parse JWKS: {}", e.getMessage());
            throw new RuntimeException("Invalid JWKS format", e);
        }
    }

    /**
     * Clear the JWKS cache (useful for key rotation)
     */
    public void clearCache() {
        jwksCache.invalidateAll();
        log.info("JWKS cache cleared");
    }

    /**
     * Result of token validation
     */
    public record TokenValidationResult(
            boolean valid,
            String userId,
            String username,
            List<String> roles,
            String errorMessage
    ) {}
}

