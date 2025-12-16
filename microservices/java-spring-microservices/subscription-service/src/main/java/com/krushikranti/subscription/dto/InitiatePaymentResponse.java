package com.krushikranti.subscription.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Response DTO for payment initiation.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InitiatePaymentResponse {
    
    private Long subscriptionId;
    private Long transactionId;
    
    private BigDecimal amount;
    private String currency;
    
    // Payment gateway details (for real gateway integration)
    private String gatewayOrderId;
    private String gatewayKey;  // Public key for client
    
    // For mock payment
    private boolean mockPayment;
    private String paymentUrl;
    
    private String status;
    private String message;
}

