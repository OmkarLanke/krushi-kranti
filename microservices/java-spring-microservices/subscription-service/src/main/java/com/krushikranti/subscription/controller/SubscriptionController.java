package com.krushikranti.subscription.controller;

import com.krushikranti.subscription.dto.*;
import com.krushikranti.subscription.service.SubscriptionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for subscription management.
 */
@RestController
@RequestMapping("/subscription")
@RequiredArgsConstructor
@Slf4j
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    /**
     * Get subscription status for the logged-in user.
     */
    @GetMapping("/status")
    public ResponseEntity<ApiResponse<SubscriptionStatusResponse>> getSubscriptionStatus(
            @RequestHeader("X-User-Id") Long userId) {
        
        log.debug("Getting subscription status for userId: {}", userId);
        
        SubscriptionStatusResponse status = subscriptionService.getSubscriptionStatus(userId);
        return ResponseEntity.ok(ApiResponse.success("Subscription status retrieved", status));
    }

    /**
     * Check if user is subscribed.
     */
    @GetMapping("/check")
    public ResponseEntity<ApiResponse<Boolean>> checkSubscription(
            @RequestHeader("X-User-Id") Long userId) {
        
        boolean isSubscribed = subscriptionService.isSubscribed(userId);
        String message = isSubscribed ? "User is subscribed" : "User is not subscribed";
        return ResponseEntity.ok(ApiResponse.success(message, isSubscribed));
    }

    /**
     * Check profile completion status before subscription.
     */
    @GetMapping("/profile-check")
    public ResponseEntity<ApiResponse<ProfileCompletionStatus>> checkProfileCompletion(
            @RequestHeader("X-User-Id") Long userId,
            @RequestHeader(value = "X-Farmer-Id", required = false) Long farmerId,
            @RequestParam(defaultValue = "false") boolean hasMyDetails,
            @RequestParam(defaultValue = "false") boolean hasFarmDetails,
            @RequestParam(defaultValue = "false") boolean hasCropDetails) {
        
        ProfileCompletionStatus status = subscriptionService.checkProfileCompletion(
                userId, farmerId, hasMyDetails, hasFarmDetails, hasCropDetails);
        
        return ResponseEntity.ok(ApiResponse.success(status.getMessage(), status));
    }

    /**
     * Initiate subscription payment.
     */
    @PostMapping("/payment/initiate")
    public ResponseEntity<ApiResponse<InitiatePaymentResponse>> initiatePayment(
            @RequestHeader("X-User-Id") Long userId,
            @RequestHeader(value = "X-Farmer-Id", required = false, defaultValue = "0") Long farmerId,
            @RequestBody(required = false) InitiatePaymentRequest request) {
        
        log.info("Initiating payment for userId: {}", userId);
        
        if (request == null) {
            request = new InitiatePaymentRequest();
        }
        
        // If farmerId not provided in header, use userId (they should be same for farmers)
        if (farmerId == null || farmerId == 0) {
            farmerId = userId;
        }
        
        InitiatePaymentResponse response = subscriptionService.initiatePayment(userId, farmerId, request);
        
        if ("FAILED".equals(response.getStatus())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(response.getMessage(), response.getMessage()));
        }
        
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    /**
     * Complete/verify subscription payment.
     */
    @PostMapping("/payment/complete")
    public ResponseEntity<ApiResponse<CompletePaymentResponse>> completePayment(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody CompletePaymentRequest request) {
        
        log.info("Completing payment for userId: {}, transactionId: {}", 
                userId, request.getTransactionId());
        
        try {
            CompletePaymentResponse response = subscriptionService.completePayment(userId, request);
            
            if (response.isSuccess()) {
                return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
            } else {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error(response.getMessage(), response.getMessage()));
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Mock payment page (for testing without real payment gateway).
     * In production, this would redirect to actual payment gateway.
     */
    @GetMapping("/payment/mock/{transactionId}")
    public ResponseEntity<ApiResponse<String>> getMockPaymentPage(
            @PathVariable Long transactionId) {
        
        String mockPaymentHtml = """
            <html>
            <head><title>Mock Payment - Krushi Kranti</title></head>
            <body style="font-family: Arial; padding: 20px; text-align: center;">
                <h1>Mock Payment Gateway</h1>
                <h2>Subscription: ₹999/year</h2>
                <p>Transaction ID: %d</p>
                <p>This is a mock payment page for testing.</p>
                <br/>
                <button onclick="completePayment('SUCCESS')" style="background: green; color: white; padding: 15px 30px; font-size: 18px; margin: 10px;">
                    Pay ₹999 (Success)
                </button>
                <button onclick="completePayment('FAILED')" style="background: red; color: white; padding: 15px 30px; font-size: 18px; margin: 10px;">
                    Cancel Payment (Fail)
                </button>
                <script>
                    function completePayment(status) {
                        // In real app, this would call the complete payment API
                        alert('Payment ' + status + '! Call POST /subscription/payment/complete with mockPaymentStatus=' + status);
                    }
                </script>
            </body>
            </html>
            """.formatted(transactionId);
        
        return ResponseEntity.ok(ApiResponse.success("Mock payment page", mockPaymentHtml));
    }
}

