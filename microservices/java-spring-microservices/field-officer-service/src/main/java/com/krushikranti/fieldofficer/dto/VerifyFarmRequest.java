package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Request DTO for verifying a farm
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyFarmRequest {
    
    @NotNull(message = "Farm ID is required")
    private Long farmId;
    
    @NotNull(message = "Verification status is required")
    private String verificationStatus; // VERIFIED, REJECTED
    
    private String feedback; // General feedback
    
    private String rejectionReason; // Required if status is REJECTED
    
    private Double latitude; // GPS coordinates
    
    private Double longitude;
    
    private List<String> photoUrls; // URLs of uploaded photos (from File Service)
}

