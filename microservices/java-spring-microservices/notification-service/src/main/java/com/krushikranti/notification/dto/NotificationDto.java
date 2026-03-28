package com.krushikranti.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Data Transfer Object for Notification.
 * Used to avoid exposing the entity directly to API responses.
 *
 * SECURITY: This DTO intentionally excludes:
 * - recipientPhoneNumber (privacy)
 * - raw data field - only exposes parsed/sanitized dataSummary
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDto {

    private Long id;
    private String eventType;
    private Long recipientUserId;
    private String title;
    private String message;
    private String priority;
    private Boolean isRead;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;

    /**
     * Summary of data field (for non-sensitive display).
     * OTPs and sensitive data should NOT be exposed here.
     */
    private String dataSummary;
}
