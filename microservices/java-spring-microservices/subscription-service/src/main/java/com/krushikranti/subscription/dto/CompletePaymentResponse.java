package com.krushikranti.subscription.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for payment completion.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompletePaymentResponse {
    
    private Long subscriptionId;
    private Long transactionId;
    
    private boolean success;
    private String subscriptionStatus;
    private String paymentStatus;
    
    private LocalDateTime subscriptionStartDate;
    private LocalDateTime subscriptionEndDate;
    
    private String message;
}

