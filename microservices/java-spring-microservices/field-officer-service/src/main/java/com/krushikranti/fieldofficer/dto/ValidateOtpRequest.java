package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for validating OTP
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidateOtpRequest {
    
    @NotNull(message = "Farm ID is required")
    private Long farmId;
    
    @NotBlank(message = "OTP is required")
    private String otp;
}

