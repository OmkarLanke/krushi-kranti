package com.krushikranti.fieldofficer.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
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
    
    @JsonProperty("isValid")
    private boolean isValid;
    
    private String message;
}

