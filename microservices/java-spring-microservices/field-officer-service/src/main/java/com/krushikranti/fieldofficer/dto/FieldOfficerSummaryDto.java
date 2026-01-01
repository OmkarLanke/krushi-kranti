package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for field officer list view - summary information
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldOfficerSummaryDto {
    
    private Long fieldOfficerId;
    private Long userId;
    
    // Basic Info
    private String fullName;
    private String username;
    private String phoneNumber;
    private String email;
    private String pincode;
    private String village;
    private String district;
    private String state;
    
    // Status
    private Boolean isActive;
    
    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime lastUpdatedAt;
}

