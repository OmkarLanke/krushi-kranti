package com.krushikranti.subscription.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entity representing a farmer's subscription.
 */
@Entity
@Table(name = "subscriptions")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subscription_id")
    private Long id;

    @Column(name = "farmer_id", nullable = false)
    private Long farmerId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "subscription_status", nullable = false, length = 20)
    @Builder.Default
    private SubscriptionStatus subscriptionStatus = SubscriptionStatus.PENDING;

    @Column(name = "subscription_start_date")
    private LocalDateTime subscriptionStartDate;

    @Column(name = "subscription_end_date")
    private LocalDateTime subscriptionEndDate;

    @Column(name = "subscription_amount", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal subscriptionAmount = new BigDecimal("999.00");

    @Column(name = "currency", nullable = false, length = 3)
    @Builder.Default
    private String currency = "INR";

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false, length = 20)
    @Builder.Default
    private PaymentStatus paymentStatus = PaymentStatus.PENDING;

    @Column(name = "payment_transaction_id", length = 100)
    private String paymentTransactionId;

    @Column(name = "payment_gateway", length = 50)
    private String paymentGateway;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod;

    @Column(name = "payment_date")
    private LocalDateTime paymentDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    /**
     * Check if subscription is currently active
     */
    public boolean isActive() {
        return subscriptionStatus == SubscriptionStatus.ACTIVE &&
               subscriptionEndDate != null &&
               subscriptionEndDate.isAfter(LocalDateTime.now());
    }

    /**
     * Subscription status enum
     */
    public enum SubscriptionStatus {
        PENDING,    // Awaiting payment
        ACTIVE,     // Paid and valid
        EXPIRED,    // Past end date
        CANCELLED   // User cancelled
    }

    /**
     * Payment status enum
     */
    public enum PaymentStatus {
        PENDING,    // Not started
        INITIATED,  // Payment started
        COMPLETED,  // Payment successful
        FAILED,     // Payment failed
        REFUNDED    // Money returned
    }
}

