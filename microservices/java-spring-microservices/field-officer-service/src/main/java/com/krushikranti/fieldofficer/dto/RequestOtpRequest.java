package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for requesting OTP for farm verification
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestOtpRequest {
    
    @NotNull(message = "Farm ID is required")
    private Long farmId;
}

