package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for suggested field officers based on pincode matching
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuggestedFieldOfficerDto {
    
    private Long fieldOfficerId;
    private Long userId;
    
    // Basic Info
    private String fullName;
    private String username;
    private String phoneNumber;
    private String email;
    
    // Location Info
    private String pincode;
    private String village;
    private String district;
    private String state;
    
    // Status
    private Boolean isActive;
    
    // Matching Info
    private List<String> matchingPincodes; // List of farm pincodes that match this FO's pincode
    private Integer matchingFarmCount; // Number of farms with matching pincode
}

