package com.krushikranti.auth.service;

import com.krushikranti.auth.config.RsaKeyProvider;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Date;
import java.util.List;

/**
 * JWT Service using RSA (RS256) for token signing and verification.
 * Tokens signed with private key can be verified using public key from JWKS endpoint.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class JwtService {

    private final RsaKeyProvider rsaKeyProvider;

    @Value("${jwt.expiration}")
    private long expiration;

    @Value("${jwt.issuer}")
    private String issuer;

    /**
     * Generate a JWT token signed with RSA private key
     */
    public String generateToken(String userId, String username, List<String> roles) {
        try {
            JWSSigner signer = new RSASSASigner(rsaKeyProvider.getPrivateKey());
            
            JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                    .subject(userId)
                    .issuer(issuer)
                    .claim("username", username)
                    .claim("roles", roles)
                    .issueTime(Date.from(Instant.now()))
                    .expirationTime(Date.from(Instant.now().plusMillis(expiration)))
                    .build();

            // Include key ID in header for JWKS lookup
            JWSHeader header = new JWSHeader.Builder(JWSAlgorithm.RS256)
                    .keyID(rsaKeyProvider.getKeyId())
                    .build();

            SignedJWT signedJWT = new SignedJWT(header, claimsSet);
            signedJWT.sign(signer);
            
            log.debug("Generated JWT token for user: {}", username);
            return signedJWT.serialize();
        } catch (JOSEException e) {
            log.error("Error generating JWT token", e);
            throw new RuntimeException("Failed to generate token", e);
        }
    }

    /**
     * Validate a JWT token using RSA public key
     */
    public boolean validateToken(String token) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            JWSVerifier verifier = new RSASSAVerifier(rsaKeyProvider.getPublicKey());
            
            if (!signedJWT.verify(verifier)) {
                log.warn("Token signature verification failed");
                return false;
            }

            JWTClaimsSet claimsSet = signedJWT.getJWTClaimsSet();
            
            // Verify issuer
            if (!issuer.equals(claimsSet.getIssuer())) {
                log.warn("Token issuer mismatch. Expected: {}, Got: {}", issuer, claimsSet.getIssuer());
                return false;
            }
            
            // Verify expiration
            Date expirationTime = claimsSet.getExpirationTime();
            if (expirationTime == null || expirationTime.before(Date.from(Instant.now()))) {
                log.warn("Token has expired");
                return false;
            }
            
            return true;
        } catch (Exception e) {
            log.error("Error validating token: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Parse and return JWT claims
     */
    public JWTClaimsSet getClaims(String token) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            return signedJWT.getJWTClaimsSet();
        } catch (Exception e) {
            log.error("Error parsing token claims", e);
            return null;
        }
    }

    /**
     * Extract user ID from token
     */
    public String getUserId(String token) {
        JWTClaimsSet claims = getClaims(token);
        return claims != null ? claims.getSubject() : null;
    }

    /**
     * Extract roles from token
     */
    @SuppressWarnings("unchecked")
    public List<String> getRoles(String token) {
        JWTClaimsSet claims = getClaims(token);
        if (claims != null) {
            Object rolesObj = claims.getClaim("roles");
            if (rolesObj instanceof List) {
                return (List<String>) rolesObj;
            }
        }
        return List.of();
    }

    /**
     * Extract username from token
     */
    public String getUsername(String token) {
        JWTClaimsSet claims = getClaims(token);
        return claims != null ? (String) claims.getClaim("username") : null;
    }

    /**
     * Get the issuer for this JWT service
     */
    public String getIssuer() {
        return issuer;
    }
}
