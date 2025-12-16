package com.krushikranti.subscription.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for completing/verifying payment.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompletePaymentRequest {
    
    @NotNull(message = "Transaction ID is required")
    private Long transactionId;
    
    // For real payment gateway verification
    private String gatewayPaymentId;
    private String gatewayOrderId;
    private String gatewaySignature;
    
    // For mock payment
    private boolean mockPayment;
    private String mockPaymentStatus;  // "SUCCESS" or "FAILED"
}

