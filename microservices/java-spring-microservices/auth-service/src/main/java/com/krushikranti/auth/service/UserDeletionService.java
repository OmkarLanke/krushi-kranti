package com.krushikranti.auth.service;

import com.krushikranti.auth.events.UserDeletionEvent;
import com.krushikranti.auth.model.User;
import com.krushikranti.auth.repository.RefreshTokenRepository;
import com.krushikranti.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

/**
 * Service for managing user deletion with cascading cleanup across all services.
 * Publishes USER_DELETION_EVENTS to Kafka for other services to clean up related data.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDeletionService {

    private static final String USER_DELETION_TOPIC = "USER_DELETION_EVENTS";

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final StringRedisTemplate redisTemplate;
    private final KafkaTemplate<String, UserDeletionEvent> kafkaTemplate;

    /**
     * Delete a user and publish deletion event to Kafka for cascading cleanup.
     *
     * @param userId        The ID of the user to delete
     * @param deletionReason Optional reason for deletion
     * @param deletedBy     ID of the admin/user performing the deletion
     * @return true if user was deleted, false if user not found
     */
    @Transactional
    public boolean deleteUser(Long userId, String deletionReason, Long deletedBy) {
        log.info("Attempting to delete user with ID: {}", userId);

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            log.warn("User not found for deletion: {}", userId);
            return false;
        }

        User user = userOpt.get();

        // Build deletion event before deleting the user (to capture all details)
        UserDeletionEvent event = UserDeletionEvent.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole().name())
                .deletionReason(deletionReason)
                .deletedBy(deletedBy)
                .deletedAt(LocalDateTime.now())
                .build();

        // 1. Delete refresh tokens for this user
        try {
            refreshTokenRepository.deleteByUserId(userId);
            log.info("Deleted refresh tokens for user: {}", userId);
        } catch (Exception e) {
            log.warn("Error deleting refresh tokens for user {}: {}", userId, e.getMessage());
        }

        // 2. Clean up OTP and password reset data from Redis
        cleanupRedisData(user);

        // 3. Delete user from auth database
        userRepository.delete(user);
        log.info("User deleted from auth-db: {} ({})", user.getUsername(), userId);

        // 4. Publish deletion event to Kafka for other services
        publishDeletionEvent(event);

        return true;
    }

    /**
     * Delete a user by email address.
     */
    @Transactional
    public boolean deleteUserByEmail(String email, String deletionReason, Long deletedBy) {
        Optional<User> userOpt = userRepository.findByEmail(email.toLowerCase().trim());
        if (userOpt.isEmpty()) {
            log.warn("User not found for deletion by email: {}", email);
            return false;
        }
        return deleteUser(userOpt.get().getId(), deletionReason, deletedBy);
    }

    /**
     * Delete a user by phone number.
     */
    @Transactional
    public boolean deleteUserByPhoneNumber(String phoneNumber, String deletionReason, Long deletedBy) {
        Optional<User> userOpt = userRepository.findByPhoneNumber(phoneNumber);
        if (userOpt.isEmpty()) {
            log.warn("User not found for deletion by phone: {}", phoneNumber);
            return false;
        }
        return deleteUser(userOpt.get().getId(), deletionReason, deletedBy);
    }

    /**
     * Clean up Redis data for the user (OTP, password reset tokens, rate limits).
     */
    private void cleanupRedisData(User user) {
        try {
            // Clean up OTP data
            String otpKey = "otp:" + user.getPhoneNumber();
            redisTemplate.delete(otpKey);

            // Clean up password reset rate limits
            String rateLimitKey = "password_reset_rate_limit:" + user.getEmail().toLowerCase();
            redisTemplate.delete(rateLimitKey);

            // Clean up any password reset tokens (scan and delete)
            // This is a pattern search - in production, consider storing user's tokens in a set
            log.info("Cleaned up Redis data for user: {} ({})", user.getUsername(), user.getId());
        } catch (Exception e) {
            log.warn("Error cleaning up Redis data for user {}: {}", user.getId(), e.getMessage());
        }
    }

    /**
     * Publish user deletion event to Kafka.
     */
    private void publishDeletionEvent(UserDeletionEvent event) {
        try {
            CompletableFuture<SendResult<String, UserDeletionEvent>> future = 
                    kafkaTemplate.send(USER_DELETION_TOPIC, event.getUserId().toString(), event);

            future.whenComplete((result, ex) -> {
                if (ex == null) {
                    log.info("User deletion event published successfully - UserId: {}, Topic: {}, Partition: {}, Offset: {}",
                            event.getUserId(),
                            result.getRecordMetadata().topic(),
                            result.getRecordMetadata().partition(),
                            result.getRecordMetadata().offset());
                } else {
                    log.error("Failed to publish user deletion event for userId {}: {}",
                            event.getUserId(), ex.getMessage(), ex);
                }
            });
        } catch (Exception e) {
            // Don't fail the deletion if Kafka publishing fails
            // The user is already deleted from auth-db
            // Other services may need manual cleanup in this case
            log.error("Exception publishing user deletion event for userId {}: {}",
                    event.getUserId(), e.getMessage(), e);
        }
    }
}
