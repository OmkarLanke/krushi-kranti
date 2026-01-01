package com.krushikranti.farmer.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for admin farmer list view - summary information
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminFarmerSummaryDto {
    
    private Long farmerId;
    private Long userId;
    
    // Basic Info
    private String fullName;
    private String username;
    private String phoneNumber;
    private String email;
    private String village;
    private String district;
    private String state;
    
    // Status flags
    private Boolean isProfileComplete;
    private String kycStatus;          // PENDING, PARTIAL, VERIFIED
    private String subscriptionStatus; // PENDING, ACTIVE, EXPIRED, CANCELLED
    
    // Counts
    private Integer farmCount;
    private Integer verifiedFarmCount;
    
    // Assignment Summary
    private Integer assignedFarmsCount;  // Number of farms that have assignments
    private Integer totalFarmsCount;     // Total farms (same as farmCount, but explicit for clarity)
    private Boolean hasAllFarmsAssigned; // True if all farms are assigned
    private Boolean hasPartialAssignment; // True if some but not all farms are assigned
    
    // Timestamps
    private LocalDateTime registeredAt;
    private LocalDateTime lastUpdatedAt;
}

