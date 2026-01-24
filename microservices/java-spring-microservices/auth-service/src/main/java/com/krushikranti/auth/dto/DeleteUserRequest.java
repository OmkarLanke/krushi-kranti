package com.krushikranti.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for user deletion
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeleteUserRequest {
    
    /**
     * User ID to delete (optional if email or phoneNumber provided)
     */
    private Long userId;
    
    /**
     * Email of user to delete (alternative to userId)
     */
    private String email;
    
    /**
     * Phone number of user to delete (alternative to userId)
     */
    private String phoneNumber;
    
    /**
     * Reason for deletion (for audit purposes)
     */
    private String reason;
}
