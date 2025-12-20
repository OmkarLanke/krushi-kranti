package com.krushikranti.kyc.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * Request DTO for PAN verification.
 */
@Data
public class PanVerifyRequest {
    
    @NotBlank(message = "PAN number is required")
    @Pattern(regexp = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$", 
             message = "Invalid PAN format. Must be in format XXXXX1234X")
    private String panNumber;
}

