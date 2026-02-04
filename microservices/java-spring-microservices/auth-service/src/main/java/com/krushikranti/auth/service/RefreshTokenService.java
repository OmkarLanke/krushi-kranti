package com.krushikranti.auth.service;

import com.krushikranti.auth.model.RefreshToken;
import com.krushikranti.auth.model.User;
import com.krushikranti.auth.repository.RefreshTokenRepository;
import com.krushikranti.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Objects;
import java.util.Optional;

/**
 * Service for managing refresh tokens.
 * Refresh tokens are used to obtain new access tokens without re-authentication.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration; // in milliseconds

    private static final SecureRandom secureRandom = new SecureRandom();
    private static final Base64.Encoder base64Encoder = Base64.getUrlEncoder().withoutPadding();

    /**
     * Generate a new refresh token for a user.
     * Revokes any existing refresh tokens for the user (single active token per user).
     */
    @Transactional
    public String createRefreshToken(Long userId) {
        // Fail fast if userId is null
        Objects.requireNonNull(userId, "userId must not be null");
        
        // Revoke existing tokens for this user (optional: can allow multiple tokens)
        refreshTokenRepository.revokeAllUserTokens(userId);

        // Generate a secure random token
        byte[] randomBytes = new byte[64];
        secureRandom.nextBytes(randomBytes);
        String tokenValue = base64Encoder.encodeToString(randomBytes);

        // Calculate expiration time
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(refreshExpiration / 1000);

        // Create and save refresh token
        RefreshToken refreshToken = RefreshToken.builder()
                .userId(userId)
                .token(tokenValue)
                .expiresAt(expiresAt)
                .isRevoked(false)
                .build();

        refreshTokenRepository.save(refreshToken);
        log.info("Created refresh token for user: {}", userId);

        return tokenValue;
    }

    /**
     * Validate a refresh token and return the associated user if valid.
     */
    @Transactional(readOnly = true)
    public Optional<User> validateRefreshToken(String token) {
        Optional<RefreshToken> refreshTokenOpt = refreshTokenRepository.findByToken(token);

        if (refreshTokenOpt.isEmpty()) {
            log.warn("Refresh token not found");
            return Optional.empty();
        }

        RefreshToken refreshToken = refreshTokenOpt.get();

        // Check if token is revoked
        if (refreshToken.getIsRevoked()) {
            log.warn("Refresh token is revoked for user: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        // Check if token is expired
        if (refreshToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            log.warn("Refresh token is expired for user: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        // Find the associated user
        Optional<User> userOpt = userRepository.findById(refreshToken.getUserId());
        if (userOpt.isEmpty()) {
            log.warn("User not found for refresh token: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        User user = userOpt.get();

        // Check if user is still active
        if (!user.getIsActive()) {
            log.warn("User account is inactive: {}", user.getId());
            return Optional.empty();
        }

        log.debug("Refresh token validated successfully for user: {}", user.getId());
        return Optional.of(user);
    }

    /**
     * Revoke a specific refresh token.
     */
    @Transactional
    public void revokeToken(String token) {
        Optional<RefreshToken> refreshTokenOpt = refreshTokenRepository.findByToken(token);
        if (refreshTokenOpt.isPresent()) {
            RefreshToken refreshToken = refreshTokenOpt.get();
            refreshToken.setIsRevoked(true);
            refreshTokenRepository.save(refreshToken);
            log.info("Revoked refresh token for user: {}", refreshToken.getUserId());
        }
    }

    /**
     * Revoke all refresh tokens for a user.
     */
    @Transactional
    public void revokeAllUserTokens(Long userId) {
        refreshTokenRepository.revokeAllUserTokens(userId);
        log.info("Revoked all refresh tokens for user: {}", userId);
    }

    /**
     * Rotate refresh token: create a new token (which implicitly revokes all old ones).
     * This provides additional security by limiting token lifetime.
     * Note: createRefreshToken already calls revokeAllUserTokens, so explicit
     * revokeToken(oldToken) is not needed and would be redundant.
     */
    @Transactional
    public String rotateRefreshToken(String oldToken, Long userId) {
        // Create a new token (this automatically revokes all existing tokens for the user)
        return createRefreshToken(userId);
    }

    /**
     * Atomically validate and rotate a refresh token.
     * This method prevents TOCTOU race conditions by performing validation and rotation
     * in a single transaction. If two parallel requests use the same token, only one
     * will succeed (the first one to execute will revoke the token, causing the second to fail).
     * 
     * @param token The refresh token to validate and rotate
     * @return RefreshTokenResult containing the user and new token if successful, empty otherwise
     */
    @Transactional
    public Optional<RefreshTokenResult> validateAndRotateRefreshToken(String token) {
        Optional<RefreshToken> refreshTokenOpt = refreshTokenRepository.findByToken(token);

        if (refreshTokenOpt.isEmpty()) {
            log.warn("Refresh token not found");
            return Optional.empty();
        }

        RefreshToken refreshToken = refreshTokenOpt.get();

        // Check if token is revoked (handles race condition - second request will see revoked token)
        if (refreshToken.getIsRevoked()) {
            log.warn("Refresh token is revoked for user: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        // Check if token is expired
        if (refreshToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            log.warn("Refresh token is expired for user: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        // Find the associated user
        Optional<User> userOpt = userRepository.findById(refreshToken.getUserId());
        if (userOpt.isEmpty()) {
            log.warn("User not found for refresh token: {}", refreshToken.getUserId());
            return Optional.empty();
        }

        User user = userOpt.get();

        // Check if user is still active
        if (!user.getIsActive()) {
            log.warn("User account is inactive: {}", user.getId());
            return Optional.empty();
        }

        // Atomically create new token (this revokes all existing tokens including the current one)
        String newToken = createRefreshToken(user.getId());
        
        log.debug("Refresh token validated and rotated successfully for user: {}", user.getId());
        return Optional.of(new RefreshTokenResult(user, newToken));
    }

    /**
     * Result class for validateAndRotateRefreshToken operation.
     */
    public record RefreshTokenResult(User user, String newRefreshToken) {}

    /**
     * Scheduled task to clean up expired and revoked tokens.
     * Runs every hour.
     */
    @Scheduled(fixedRate = 3600000) // Every hour
    @Transactional
    public void cleanupExpiredTokens() {
        refreshTokenRepository.deleteExpiredOrRevokedTokens(LocalDateTime.now());
        log.debug("Cleaned up expired and revoked refresh tokens");
    }

    /**
     * Get refresh token expiration time in seconds (for response).
     */
    public long getRefreshExpirationSeconds() {
        return refreshExpiration / 1000;
    }
}
