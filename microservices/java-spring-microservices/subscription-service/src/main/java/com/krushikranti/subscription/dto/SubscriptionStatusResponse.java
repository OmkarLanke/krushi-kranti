package com.krushikranti.subscription.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Response DTO for subscription status check.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionStatusResponse {
    
    private Long subscriptionId;
    private Long farmerId;
    private Long userId;
    
    private boolean isSubscribed;
    private String subscriptionStatus;
    private String paymentStatus;
    
    private LocalDateTime subscriptionStartDate;
    private LocalDateTime subscriptionEndDate;
    private Integer daysRemaining;
    
    private BigDecimal subscriptionAmount;
    private String currency;
    
    // Profile completion status (for subscription eligibility)
    private boolean profileCompleted;
    private boolean hasMyDetails;
    private boolean hasFarmDetails;
    private boolean hasCropDetails;
    
    private String message;
}

