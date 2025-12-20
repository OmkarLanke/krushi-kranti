package com.krushikranti.kyc.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * Request DTO for Aadhaar OTP verification.
 */
@Data
public class AadhaarVerifyOtpRequest {
    
    @NotBlank(message = "Request ID is required")
    private String requestId;
    
    @NotBlank(message = "OTP is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "OTP must be 6 digits")
    private String otp;
}

