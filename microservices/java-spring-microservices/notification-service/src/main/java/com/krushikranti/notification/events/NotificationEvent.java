package com.krushikranti.notification.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Event consumed from Kafka NOTIFICATION_EVENTS topic
 * for farm verification OTP notifications and other notification types
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationEvent {
    
    private String eventType; // FARM_VERIFICATION_OTP
    private Long recipientUserId; // Farmer's user ID
    private String recipientPhoneNumber; // Farmer's phone number
    private String title; // Notification title
    private String message; // Notification message
    private Map<String, Object> data; // Additional data (OTP, farmId, fieldOfficerName, etc.)
    private LocalDateTime timestamp;
    private String priority; // HIGH, MEDIUM, LOW
}
