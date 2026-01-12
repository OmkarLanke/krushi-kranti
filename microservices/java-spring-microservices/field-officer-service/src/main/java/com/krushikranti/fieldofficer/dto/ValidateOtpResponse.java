package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO for OTP validation
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidateOtpResponse {
    
    private Long farmId;
    private boolean isValid;
    private String message;
}

