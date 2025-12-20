package com.krushikranti.kyc.dto;

import lombok.Builder;
import lombok.Data;

/**
 * Response DTO for Aadhaar OTP generation.
 */
@Data
@Builder
public class AadhaarGenerateOtpResponse {
    
    private Boolean otpSent;
    private String requestId;  // To be used for OTP submission
    private String message;
}

