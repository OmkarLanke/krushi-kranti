package com.krushikranti.auth.service;

import com.krushikranti.auth.model.User;
import com.krushikranti.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Service for handling password reset functionality.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final StringRedisTemplate redisTemplate;
    private final WebClient.Builder webClientBuilder;

    @Value("${app.password-reset.token-expiration:1800}") // 30 minutes default
    private long tokenExpirationSeconds;

    @Value("${app.password-reset.rate-limit:3}")
    private int rateLimitPerHour;

    @Value("${app.services.notification-service:http://localhost:4016}")
    private String notificationServiceUrl;

    private static final String REDIS_KEY_PREFIX = "password_reset_token:";
    private static final String RATE_LIMIT_KEY_PREFIX = "password_reset_rate_limit:";

    /**
     * Request password reset - generates token and sends email
     *
     * @param email User's email address
     * @return Success message
     * @throws ResponseStatusException if email doesn't exist or account is inactive
     */
    public String requestPasswordReset(String email) {
        log.info("Password reset requested for email: {}", email);

        // Find user by email
        Optional<User> userOpt = userRepository.findByEmail(email.toLowerCase().trim());
        
        // Throw exception if email doesn't exist
        if (userOpt.isEmpty()) {
            log.warn("Password reset requested for non-existent email: {}", email);
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, 
                    "No account found with this email address. Please check your email and try again.");
        }

        User user = userOpt.get();

        // Check if user is active
        if (!Boolean.TRUE.equals(user.getIsActive())) {
            log.warn("Password reset requested for inactive account: {}", email);
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, 
                    "This account is inactive. Please contact support for assistance.");
        }

        // Rate limiting - check if too many requests
        String rateLimitKey = RATE_LIMIT_KEY_PREFIX + email.toLowerCase().trim();
        String rateLimitCount = redisTemplate.opsForValue().get(rateLimitKey);
        
        if (rateLimitCount != null && Integer.parseInt(rateLimitCount) >= rateLimitPerHour) {
            log.warn("Password reset rate limit exceeded for email: {}", email);
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, 
                    "Too many password reset requests. Please wait before requesting again.");
        }

        // Generate secure reset token
        String resetToken = UUID.randomUUID().toString() + "-" + System.currentTimeMillis();
        String tokenKey = REDIS_KEY_PREFIX + resetToken;

        // Store token in Redis with expiration
        redisTemplate.opsForValue().set(tokenKey, String.valueOf(user.getId()), 
                Duration.ofSeconds(tokenExpirationSeconds));

        // Update rate limit counter
        if (rateLimitCount == null) {
            redisTemplate.opsForValue().set(rateLimitKey, "1", Duration.ofHours(1));
        } else {
            redisTemplate.opsForValue().increment(rateLimitKey);
        }

        log.info("Password reset token generated for user ID: {}, email: {}", user.getId(), email);

        // Send email via notification service
        sendPasswordResetEmail(user.getEmail(), user.getUsername(), resetToken);

        return "Password reset link has been sent to your email. Please check your inbox.";
    }

    /**
     * Verify if reset token is valid
     *
     * @param token Reset token
     * @return User ID if token is valid, empty otherwise
     */
    public Optional<Long> verifyResetToken(String token) {
        log.info("Verifying password reset token");

        String tokenKey = REDIS_KEY_PREFIX + token;
        String userIdStr = redisTemplate.opsForValue().get(tokenKey);

        if (userIdStr == null) {
            log.warn("Invalid or expired password reset token");
            return Optional.empty();
        }

        try {
            Long userId = Long.parseLong(userIdStr);
            log.info("Password reset token verified for user ID: {}", userId);
            return Optional.of(userId);
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format in token: {}", userIdStr, e);
            return Optional.empty();
        }
    }

    /**
     * Reset password using token
     *
     * @param token Reset token
     * @param newPassword New password
     * @throws ResponseStatusException if token is invalid or password validation fails
     */
    @Transactional
    public void resetPassword(String token, String newPassword) {
        log.info("Password reset requested with token");

        // Verify token
        Optional<Long> userIdOpt = verifyResetToken(token);
        if (userIdOpt.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, 
                    "Invalid or expired reset token");
        }

        Long userId = userIdOpt.get();

        // Find user
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            log.error("User not found for password reset - User ID: {}", userId);
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found");
        }

        User user = userOpt.get();

        // Validate password strength
        if (newPassword == null || newPassword.length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, 
                    "Password must be at least 8 characters long");
        }

        // Update password
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Invalidate token (delete from Redis)
        String tokenKey = REDIS_KEY_PREFIX + token;
        redisTemplate.delete(tokenKey);

        log.info("Password reset successful for user ID: {}, email: {}", userId, user.getEmail());
    }

    /**
     * Send password reset email via notification service
     */
    private void sendPasswordResetEmail(String email, String userName, String resetToken) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(notificationServiceUrl).build();

            Map<String, String> requestBody = Map.of(
                    "email", email,
                    "userName", userName != null ? userName : "User",
                    "resetToken", resetToken
            );

            webClient.post()
                    .uri("/email/password-reset")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(Duration.ofSeconds(10))
                    .doOnSuccess(response -> log.info("Password reset email sent successfully to: {}", email))
                    .doOnError(error -> log.error("Failed to send password reset email to: {}", email, error))
                    .block();

        } catch (Exception e) {
            log.error("Error calling notification service to send password reset email: {}", e.getMessage(), e);
            // Don't throw exception - email sending failure shouldn't block the flow
            // The token is still valid and user can request again
        }
    }
}
