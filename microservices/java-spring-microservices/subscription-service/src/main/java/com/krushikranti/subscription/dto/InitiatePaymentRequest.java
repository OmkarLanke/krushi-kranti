package com.krushikranti.subscription.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for initiating subscription payment.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InitiatePaymentRequest {
    
    // Payment method (optional - for future use)
    private String paymentMethod;
    
    // Coupon code (optional - for future use)
    private String couponCode;
}

