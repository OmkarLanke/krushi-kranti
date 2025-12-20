package com.krushikranti.kyc.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * Request DTO for Aadhaar OTP generation.
 */
@Data
public class AadhaarGenerateOtpRequest {
    
    @NotBlank(message = "Aadhaar number is required")
    @Pattern(regexp = "^[0-9]{12}$", 
             message = "Invalid Aadhaar format. Must be 12 digits")
    private String aadhaarNumber;
}

