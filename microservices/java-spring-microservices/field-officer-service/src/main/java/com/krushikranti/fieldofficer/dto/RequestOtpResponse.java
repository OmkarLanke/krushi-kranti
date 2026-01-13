package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for OTP request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestOtpResponse {
    
    private Long farmId;
    private String message; // "OTP sent successfully to farmer"
    private LocalDateTime expiresAt; // OTP expiration time
    private int expirationMinutes; // OTP expiration in minutes
}

