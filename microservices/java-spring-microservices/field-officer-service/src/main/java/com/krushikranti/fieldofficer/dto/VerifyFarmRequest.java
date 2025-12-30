package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for farm verification
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyFarmRequest {
    
    @NotNull(message = "Farm ID is required")
    private Long farmId;
    
    @NotNull(message = "Verification status is required")
    private String status; // VERIFIED, REJECTED
    
    private String feedback; // Notes/feedback for verification or rejection
    
    private String rejectionReason; // Specific reason if rejected
    
    private Double latitude; // GPS latitude (optional)
    
    private Double longitude; // GPS longitude (optional)
}
