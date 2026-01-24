package com.krushikranti.auth.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Event published to Kafka USER_DELETION_EVENTS topic
 * when a user is deleted from the system.
 * All services should listen to this event and clean up related data.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDeletionEvent {
    
    /**
     * The unique user ID being deleted
     */
    private Long userId;
    
    /**
     * Username of the deleted user (for logging/audit purposes)
     */
    private String username;
    
    /**
     * Email of the deleted user
     */
    private String email;
    
    /**
     * Phone number of the deleted user
     */
    private String phoneNumber;
    
    /**
     * Role of the deleted user (FARMER, FIELD_OFFICER, ADMIN, etc.)
     */
    private String role;
    
    /**
     * Reason for deletion (optional)
     */
    private String deletionReason;
    
    /**
     * ID of the admin/user who initiated the deletion
     */
    private Long deletedBy;
    
    /**
     * Timestamp when the deletion occurred
     */
    private LocalDateTime deletedAt;
}
