package com.krushikranti.auth.controller;

import com.krushikranti.auth.config.RsaKeyProvider;
import com.krushikranti.auth.service.JwtService;
import com.nimbusds.jose.jwk.JWKSet;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * JWKS (JSON Web Key Set) Controller.
 * Exposes public keys for JWT signature verification.
 * This endpoint is used by API Gateway to validate tokens.
 */
@RestController
@RequestMapping("/.well-known")
@RequiredArgsConstructor
public class JwksController {

    private final RsaKeyProvider rsaKeyProvider;
    private final JwtService jwtService;

    /**
     * Returns the JSON Web Key Set containing the RSA public key.
     * This endpoint is public and used by API Gateway for token validation.
     */
    @GetMapping(value = "/jwks.json", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> getJwks() {
        JWKSet jwkSet = new JWKSet(rsaKeyProvider.getJwk());
        return ResponseEntity.ok(jwkSet.toJSONObject());
    }

    /**
     * Returns OpenID Connect discovery document.
     * Provides metadata about the auth service including JWKS URI.
     */
    @GetMapping(value = "/openid-configuration", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> getOpenIdConfiguration() {
        return ResponseEntity.ok(Map.of(
                "issuer", jwtService.getIssuer(),
                "jwks_uri", "/.well-known/jwks.json",
                "token_endpoint", "/auth/login",
                "response_types_supported", new String[]{"token"},
                "subject_types_supported", new String[]{"public"},
                "id_token_signing_alg_values_supported", new String[]{"RS256"}
        ));
    }
}
