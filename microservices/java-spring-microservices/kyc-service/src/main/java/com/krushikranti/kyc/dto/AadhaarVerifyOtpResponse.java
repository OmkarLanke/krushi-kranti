package com.krushikranti.kyc.dto;

import lombok.Builder;
import lombok.Data;

/**
 * Response DTO for Aadhaar OTP verification.
 */
@Data
@Builder
public class AadhaarVerifyOtpResponse {
    
    private Boolean verified;
    private String aadhaarNumberMasked;
    private String name;
    private String dob;
    private String gender;
    private String address;
    private String message;
}

