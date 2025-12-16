package com.krushikranti.auth.config;

import com.nimbusds.jose.jwk.RSAKey;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.UUID;

/**
 * RSA Key Provider for JWT signing and verification.
 * Generates an RSA key pair on startup for signing JWTs.
 * The public key is exposed via JWKS endpoint for token validation.
 */
@Component
@Slf4j
@Getter
public class RsaKeyProvider {

    private RSAPublicKey publicKey;
    private RSAPrivateKey privateKey;
    private String keyId;

    @Value("${jwt.rsa.key-size:2048}")
    private int keySize;

    @PostConstruct
    public void init() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(keySize);
            KeyPair keyPair = keyPairGenerator.generateKeyPair();
            
            this.publicKey = (RSAPublicKey) keyPair.getPublic();
            this.privateKey = (RSAPrivateKey) keyPair.getPrivate();
            this.keyId = UUID.randomUUID().toString();
            
            log.info("RSA key pair generated successfully. Key ID: {}", keyId);
        } catch (NoSuchAlgorithmException e) {
            log.error("Failed to generate RSA key pair", e);
            throw new RuntimeException("Failed to initialize RSA keys", e);
        }
    }

    /**
     * Get the RSA public key in JWK format for JWKS endpoint
     */
    public RSAKey getJwk() {
        return new RSAKey.Builder(publicKey)
                .keyID(keyId)
                .build();
    }
}

