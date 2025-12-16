package com.krushikranti.subscription.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for profile completion status check.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileCompletionStatus {
    
    private Long farmerId;
    private Long userId;
    
    private boolean profileCompleted;
    private boolean hasMyDetails;
    private boolean hasFarmDetails;
    private boolean hasCropDetails;
    
    private List<String> missingDetails;
    
    private boolean canSubscribe;
    private String message;
}

