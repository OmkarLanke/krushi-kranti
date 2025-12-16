package com.krushikranti.subscription.service;

import com.krushikranti.subscription.config.SubscriptionConfig;
import com.krushikranti.subscription.dto.*;
import com.krushikranti.subscription.model.PaymentTransaction;
import com.krushikranti.subscription.model.Subscription;
import com.krushikranti.subscription.repository.PaymentTransactionRepository;
import com.krushikranti.subscription.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Service for managing subscriptions and payments.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final PaymentTransactionRepository transactionRepository;
    private final SubscriptionConfig subscriptionConfig;

    /**
     * Get subscription status for a user.
     */
    @Transactional(readOnly = true)
    public SubscriptionStatusResponse getSubscriptionStatus(Long userId) {
        log.debug("Getting subscription status for userId: {}", userId);

        Optional<Subscription> subscriptionOpt = subscriptionRepository
                .findActiveSubscriptionByUserId(userId, LocalDateTime.now());

        if (subscriptionOpt.isPresent()) {
            Subscription subscription = subscriptionOpt.get();
            int daysRemaining = (int) ChronoUnit.DAYS.between(
                    LocalDateTime.now(), subscription.getSubscriptionEndDate());

            return SubscriptionStatusResponse.builder()
                    .subscriptionId(subscription.getId())
                    .farmerId(subscription.getFarmerId())
                    .userId(subscription.getUserId())
                    .isSubscribed(true)
                    .subscriptionStatus(subscription.getSubscriptionStatus().name())
                    .paymentStatus(subscription.getPaymentStatus().name())
                    .subscriptionStartDate(subscription.getSubscriptionStartDate())
                    .subscriptionEndDate(subscription.getSubscriptionEndDate())
                    .daysRemaining(daysRemaining)
                    .subscriptionAmount(subscription.getSubscriptionAmount())
                    .currency(subscription.getCurrency())
                    .profileCompleted(true)
                    .hasMyDetails(true)
                    .hasFarmDetails(true)
                    .hasCropDetails(true)
                    .message("Subscription is active")
                    .build();
        }

        // Check for any existing subscription (expired or pending)
        Optional<Subscription> anySubscription = subscriptionRepository.findByUserId(userId);
        if (anySubscription.isPresent()) {
            Subscription subscription = anySubscription.get();
            return SubscriptionStatusResponse.builder()
                    .subscriptionId(subscription.getId())
                    .farmerId(subscription.getFarmerId())
                    .userId(subscription.getUserId())
                    .isSubscribed(false)
                    .subscriptionStatus(subscription.getSubscriptionStatus().name())
                    .paymentStatus(subscription.getPaymentStatus().name())
                    .subscriptionStartDate(subscription.getSubscriptionStartDate())
                    .subscriptionEndDate(subscription.getSubscriptionEndDate())
                    .daysRemaining(0)
                    .subscriptionAmount(subscriptionConfig.getAmount())
                    .currency(subscriptionConfig.getCurrency())
                    .message("Subscription " + subscription.getSubscriptionStatus().name().toLowerCase())
                    .build();
        }

        // No subscription exists
        return SubscriptionStatusResponse.builder()
                .userId(userId)
                .isSubscribed(false)
                .subscriptionStatus("NONE")
                .paymentStatus("NONE")
                .daysRemaining(0)
                .subscriptionAmount(subscriptionConfig.getAmount())
                .currency(subscriptionConfig.getCurrency())
                .message("No subscription found")
                .build();
    }

    /**
     * Check profile completion status.
     * This will be called via HTTP to farmer-service or via gRPC.
     */
    public ProfileCompletionStatus checkProfileCompletion(Long userId, Long farmerId, 
            boolean hasMyDetails, boolean hasFarmDetails, boolean hasCropDetails) {
        
        List<String> missingDetails = new ArrayList<>();
        
        if (!hasMyDetails) {
            missingDetails.add("My Details (Personal & Address Information)");
        }
        if (!hasFarmDetails) {
            missingDetails.add("Farm Details");
        }
        if (!hasCropDetails) {
            missingDetails.add("Crop Details");
        }

        boolean profileCompleted = missingDetails.isEmpty();
        String message = profileCompleted 
                ? "Profile is complete. You can subscribe now." 
                : "Please complete the following before subscribing: " + String.join(", ", missingDetails);

        return ProfileCompletionStatus.builder()
                .farmerId(farmerId)
                .userId(userId)
                .profileCompleted(profileCompleted)
                .hasMyDetails(hasMyDetails)
                .hasFarmDetails(hasFarmDetails)
                .hasCropDetails(hasCropDetails)
                .missingDetails(missingDetails)
                .canSubscribe(profileCompleted)
                .message(message)
                .build();
    }

    /**
     * Initiate subscription payment.
     */
    @Transactional
    public InitiatePaymentResponse initiatePayment(Long userId, Long farmerId, 
            InitiatePaymentRequest request) {
        
        log.info("Initiating payment for userId: {}, farmerId: {}", userId, farmerId);

        // Check if already has active subscription
        Optional<Subscription> activeSubscription = subscriptionRepository
                .findActiveSubscriptionByUserId(userId, LocalDateTime.now());
        
        if (activeSubscription.isPresent()) {
            return InitiatePaymentResponse.builder()
                    .status("FAILED")
                    .message("Already has an active subscription")
                    .build();
        }

        // Create or get pending subscription
        Subscription subscription = subscriptionRepository.findByUserId(userId)
                .filter(s -> s.getSubscriptionStatus() == Subscription.SubscriptionStatus.PENDING)
                .orElseGet(() -> createPendingSubscription(userId, farmerId));

        // Create payment transaction
        PaymentTransaction transaction = PaymentTransaction.builder()
                .subscription(subscription)
                .farmerId(farmerId)
                .userId(userId)
                .amount(subscriptionConfig.getAmount())
                .currency(subscriptionConfig.getCurrency())
                .transactionType(PaymentTransaction.TransactionType.SUBSCRIPTION)
                .transactionStatus(PaymentTransaction.TransactionStatus.INITIATED)
                .paymentGateway("MOCK")  // Will be replaced with real gateway
                .gatewayOrderId("ORD_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .paymentMethod(request.getPaymentMethod())
                .build();

        transaction = transactionRepository.save(transaction);

        // Update subscription
        subscription.setPaymentStatus(Subscription.PaymentStatus.INITIATED);
        subscriptionRepository.save(subscription);

        log.info("Payment initiated. TransactionId: {}, OrderId: {}", 
                transaction.getId(), transaction.getGatewayOrderId());

        return InitiatePaymentResponse.builder()
                .subscriptionId(subscription.getId())
                .transactionId(transaction.getId())
                .amount(subscriptionConfig.getAmount())
                .currency(subscriptionConfig.getCurrency())
                .gatewayOrderId(transaction.getGatewayOrderId())
                .mockPayment(true)
                .status("INITIATED")
                .message("Payment initiated successfully. Complete the payment to activate subscription.")
                .build();
    }

    /**
     * Complete/verify payment.
     */
    @Transactional
    public CompletePaymentResponse completePayment(Long userId, CompletePaymentRequest request) {
        log.info("Completing payment for userId: {}, transactionId: {}", userId, request.getTransactionId());

        PaymentTransaction transaction = transactionRepository.findById(request.getTransactionId())
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (!transaction.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Transaction does not belong to this user");
        }

        Subscription subscription = transaction.getSubscription();

        // For mock payment - simulate success/failure based on request
        boolean paymentSuccess = request.isMockPayment() && 
                "SUCCESS".equalsIgnoreCase(request.getMockPaymentStatus());

        if (paymentSuccess) {
            // Update transaction
            transaction.setTransactionStatus(PaymentTransaction.TransactionStatus.SUCCESS);
            transaction.setGatewayPaymentId("PAY_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
            transaction.setGatewayResponse("{\"status\": \"success\", \"mock\": true}");

            // Activate subscription
            LocalDateTime now = LocalDateTime.now();
            subscription.setSubscriptionStatus(Subscription.SubscriptionStatus.ACTIVE);
            subscription.setPaymentStatus(Subscription.PaymentStatus.COMPLETED);
            subscription.setSubscriptionStartDate(now);
            subscription.setSubscriptionEndDate(now.plusDays(subscriptionConfig.getValidityDays()));
            subscription.setPaymentDate(now);
            subscription.setPaymentTransactionId(transaction.getGatewayPaymentId());

            transactionRepository.save(transaction);
            subscriptionRepository.save(subscription);

            log.info("Payment completed successfully. Subscription activated until: {}", 
                    subscription.getSubscriptionEndDate());

            return CompletePaymentResponse.builder()
                    .subscriptionId(subscription.getId())
                    .transactionId(transaction.getId())
                    .success(true)
                    .subscriptionStatus(subscription.getSubscriptionStatus().name())
                    .paymentStatus(subscription.getPaymentStatus().name())
                    .subscriptionStartDate(subscription.getSubscriptionStartDate())
                    .subscriptionEndDate(subscription.getSubscriptionEndDate())
                    .message("Payment successful! Your subscription is now active.")
                    .build();
        } else {
            // Payment failed
            transaction.setTransactionStatus(PaymentTransaction.TransactionStatus.FAILED);
            transaction.setFailureReason(request.isMockPayment() ? "Mock payment failed" : "Payment verification failed");
            transaction.setGatewayResponse("{\"status\": \"failed\", \"mock\": true}");

            subscription.setPaymentStatus(Subscription.PaymentStatus.FAILED);

            transactionRepository.save(transaction);
            subscriptionRepository.save(subscription);

            log.warn("Payment failed for transactionId: {}", transaction.getId());

            return CompletePaymentResponse.builder()
                    .subscriptionId(subscription.getId())
                    .transactionId(transaction.getId())
                    .success(false)
                    .subscriptionStatus(subscription.getSubscriptionStatus().name())
                    .paymentStatus(subscription.getPaymentStatus().name())
                    .message("Payment failed. Please try again.")
                    .build();
        }
    }

    /**
     * Create a pending subscription.
     */
    private Subscription createPendingSubscription(Long userId, Long farmerId) {
        Subscription subscription = Subscription.builder()
                .userId(userId)
                .farmerId(farmerId)
                .subscriptionStatus(Subscription.SubscriptionStatus.PENDING)
                .paymentStatus(Subscription.PaymentStatus.PENDING)
                .subscriptionAmount(subscriptionConfig.getAmount())
                .currency(subscriptionConfig.getCurrency())
                .build();

        return subscriptionRepository.save(subscription);
    }

    /**
     * Check if user has active subscription.
     */
    @Transactional(readOnly = true)
    public boolean isSubscribed(Long userId) {
        return subscriptionRepository
                .findActiveSubscriptionByUserId(userId, LocalDateTime.now())
                .isPresent();
    }
}

