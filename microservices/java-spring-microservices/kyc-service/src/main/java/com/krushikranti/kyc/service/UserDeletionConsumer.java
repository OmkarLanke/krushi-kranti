package com.krushikranti.kyc.service;

import com.krushikranti.kyc.events.UserDeletionEvent;
import com.krushikranti.kyc.model.KycVerification;
import com.krushikranti.kyc.repository.AadhaarOtpSessionRepository;
import com.krushikranti.kyc.repository.KycVerificationLogRepository;
import com.krushikranti.kyc.repository.KycVerificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Kafka consumer for processing user deletion events.
 * Cleans up all KYC-related data when a user is deleted from auth-service.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDeletionConsumer {

    private final KycVerificationRepository kycVerificationRepository;
    private final KycVerificationLogRepository kycVerificationLogRepository;
    private final AadhaarOtpSessionRepository aadhaarOtpSessionRepository;

    @KafkaListener(
            topics = "USER_DELETION_EVENTS",
            groupId = "kyc-service-group",
            containerFactory = "userDeletionKafkaListenerFactory"
    )
    public void consumeUserDeletionEvent(
            @Payload UserDeletionEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {
        
        try {
            log.info("Received user deletion event - Topic: {}, Partition: {}, Offset: {}, UserId: {}, Username: {}",
                    topic, partition, offset, event.getUserId(), event.getUsername());

            // Clean up all KYC data for this user
            deleteUserData(event.getUserId());

            // Acknowledge message processing
            acknowledgment.acknowledge();

            log.info("Successfully processed user deletion event - UserId: {}, Username: {}",
                    event.getUserId(), event.getUsername());

        } catch (Exception e) {
            log.error("Error processing user deletion event - UserId: {}, Error: {}",
                    event.getUserId(), e.getMessage(), e);
            // Don't acknowledge on error - message will be retried
        }
    }

    /**
     * Delete all KYC-related data for a user.
     * Order: Aadhaar OTP Sessions -> KYC Verification Logs -> KYC Verification
     */
    @Transactional
    public void deleteUserData(Long userId) {
        log.info("Starting cleanup of KYC data for userId: {}", userId);

        // 1. Delete Aadhaar OTP sessions
        try {
            aadhaarOtpSessionRepository.deleteByUserId(userId);
            log.info("Deleted Aadhaar OTP sessions for userId: {}", userId);
        } catch (Exception e) {
            log.warn("Error deleting Aadhaar OTP sessions for userId {}: {}", userId, e.getMessage());
        }

        // 2. Delete KYC verification logs
        try {
            kycVerificationLogRepository.deleteByUserId(userId);
            log.info("Deleted KYC verification logs for userId: {}", userId);
        } catch (Exception e) {
            log.warn("Error deleting KYC verification logs for userId {}: {}", userId, e.getMessage());
        }

        // 3. Delete KYC verification record
        Optional<KycVerification> kycOpt = kycVerificationRepository.findByUserId(userId);
        if (kycOpt.isPresent()) {
            kycVerificationRepository.delete(kycOpt.get());
            log.info("Deleted KYC verification record for userId: {}", userId);
        } else {
            log.info("No KYC verification record found for userId: {}. Skipping.", userId);
        }

        log.info("Completed cleanup of KYC data for userId: {}", userId);
    }
}
