package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.events.NotificationEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Kafka producer for sending notification events
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationProducer {

    private final KafkaTemplate<String, NotificationEvent> kafkaTemplate;
    private static final String NOTIFICATION_TOPIC = "NOTIFICATION_EVENTS";

    /**
     * Send farm verification OTP notification to farmer
     */
    public void sendFarmVerificationOtpNotification(
            Long farmerUserId,
            String farmerPhoneNumber,
            String otp,
            Long farmId,
            String farmName,
            String fieldOfficerName) {
        
        Map<String, Object> data = new HashMap<>();
        data.put("otp", otp);
        data.put("farmId", farmId);
        data.put("farmName", farmName);
        data.put("fieldOfficerName", fieldOfficerName);
        data.put("type", "FARM_VERIFICATION_OTP");

        NotificationEvent event = NotificationEvent.builder()
                .eventType("FARM_VERIFICATION_OTP")
                .recipientUserId(farmerUserId)
                .recipientPhoneNumber(farmerPhoneNumber)
                .title("Farm Verification OTP")
                .message(String.format(
                        "Field Officer %s is verifying your farm '%s'. Your OTP: %s",
                        fieldOfficerName, farmName, otp))
                .data(data)
                .timestamp(LocalDateTime.now())
                .priority("HIGH")
                .build();

        try {
            kafkaTemplate.send(NOTIFICATION_TOPIC, event);
            log.info("Sent farm verification OTP notification event - Farmer User ID: {}, Farm ID: {}, OTP: {}", 
                    farmerUserId, farmId, otp);
        } catch (Exception e) {
            log.error("Failed to send notification event to Kafka: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send notification: " + e.getMessage(), e);
        }
    }
}

