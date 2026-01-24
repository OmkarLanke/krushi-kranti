package com.krushikranti.fieldofficer.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Event received from Kafka USER_DELETION_EVENTS topic
 * when a user is deleted from the auth service.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDeletionEvent {
    
    private Long userId;
    private String username;
    private String email;
    private String phoneNumber;
    private String role;
    private String deletionReason;
    private Long deletedBy;
    private LocalDateTime deletedAt;
}
