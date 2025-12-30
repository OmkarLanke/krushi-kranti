package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for farm verification
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyFarmResponse {
    
    private Long verificationId;
    private Long farmId;
    private Long fieldOfficerId;
    private String status; // VERIFIED, REJECTED, PENDING, IN_PROGRESS
    private String feedback;
    private String rejectionReason;
    private Double latitude;
    private Double longitude;
    private LocalDateTime verifiedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

