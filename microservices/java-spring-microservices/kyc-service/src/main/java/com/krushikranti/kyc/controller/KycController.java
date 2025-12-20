package com.krushikranti.kyc.controller;

import com.krushikranti.kyc.dto.*;
import com.krushikranti.kyc.service.KycService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for KYC verification endpoints.
 */
@RestController
@RequestMapping("/kyc")
@RequiredArgsConstructor
@Slf4j
public class KycController {

    private final KycService kycService;

    /**
     * Get KYC status for the logged-in user.
     * 
     * GET /kyc/status
     */
    @GetMapping("/status")
    public ResponseEntity<ApiResponse<KycStatusResponse>> getKycStatus(
            @RequestHeader("X-User-Id") Long userId) {
        log.info("GET /kyc/status - userId: {}", userId);
        
        KycStatusResponse status = kycService.getKycStatus(userId);
        return ResponseEntity.ok(new ApiResponse<>("KYC status retrieved successfully", status));
    }

    /**
     * Check if user's KYC is complete.
     * 
     * GET /kyc/check
     */
    @GetMapping("/check")
    public ResponseEntity<ApiResponse<Boolean>> checkKycComplete(
            @RequestHeader("X-User-Id") Long userId) {
        log.info("GET /kyc/check - userId: {}", userId);
        
        boolean isComplete = kycService.isKycComplete(userId);
        String message = isComplete ? "KYC is complete" : "KYC is not complete";
        return ResponseEntity.ok(new ApiResponse<>(message, isComplete));
    }

    // ==================== PAN Verification ====================

    /**
     * Verify PAN number.
     * 
     * POST /kyc/pan/verify
     */
    @PostMapping("/pan/verify")
    public ResponseEntity<ApiResponse<PanVerifyResponse>> verifyPan(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody PanVerifyRequest request,
            HttpServletRequest httpRequest) {
        log.info("POST /kyc/pan/verify - userId: {}", userId);
        
        String ipAddress = getClientIpAddress(httpRequest);
        PanVerifyResponse response = kycService.verifyPan(userId, request.getPanNumber(), ipAddress);
        
        String message = response.getVerified() ? "PAN verified successfully" : "PAN verification failed";
        return ResponseEntity.ok(new ApiResponse<>(message, response));
    }

    // ==================== Aadhaar Verification ====================

    /**
     * Generate OTP for Aadhaar verification.
     * 
     * POST /kyc/aadhaar/generate-otp
     */
    @PostMapping("/aadhaar/generate-otp")
    public ResponseEntity<ApiResponse<AadhaarGenerateOtpResponse>> generateAadhaarOtp(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody AadhaarGenerateOtpRequest request,
            HttpServletRequest httpRequest) {
        log.info("POST /kyc/aadhaar/generate-otp - userId: {}", userId);
        
        String ipAddress = getClientIpAddress(httpRequest);
        AadhaarGenerateOtpResponse response = kycService.generateAadhaarOtp(
                userId, request.getAadhaarNumber(), ipAddress);
        
        String message = response.getOtpSent() ? "OTP sent successfully" : "Failed to send OTP";
        return ResponseEntity.ok(new ApiResponse<>(message, response));
    }

    /**
     * Verify Aadhaar OTP.
     * 
     * POST /kyc/aadhaar/verify-otp
     */
    @PostMapping("/aadhaar/verify-otp")
    public ResponseEntity<ApiResponse<AadhaarVerifyOtpResponse>> verifyAadhaarOtp(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody AadhaarVerifyOtpRequest request,
            HttpServletRequest httpRequest) {
        log.info("POST /kyc/aadhaar/verify-otp - userId: {}", userId);
        
        String ipAddress = getClientIpAddress(httpRequest);
        AadhaarVerifyOtpResponse response = kycService.verifyAadhaarOtp(
                userId, request.getRequestId(), request.getOtp(), ipAddress);
        
        String message = response.getVerified() ? "Aadhaar verified successfully" : "Aadhaar verification failed";
        return ResponseEntity.ok(new ApiResponse<>(message, response));
    }

    // ==================== Bank Verification ====================

    /**
     * Verify Bank Account.
     * 
     * POST /kyc/bank/verify
     */
    @PostMapping("/bank/verify")
    public ResponseEntity<ApiResponse<BankVerifyResponse>> verifyBankAccount(
            @RequestHeader("X-User-Id") Long userId,
            @Valid @RequestBody BankVerifyRequest request,
            HttpServletRequest httpRequest) {
        log.info("POST /kyc/bank/verify - userId: {}", userId);
        
        try {
            String ipAddress = getClientIpAddress(httpRequest);
            BankVerifyResponse response = kycService.verifyBankAccount(
                    userId, request.getAccountNumber(), request.getIfscCode(), ipAddress);
            
            String message = response.getVerified() ? "Bank account verified successfully" : "Bank verification failed";
            return ResponseEntity.ok(new ApiResponse<>(message, response));
        } catch (RuntimeException e) {
            log.error("Bank verification error for userId: {}", userId, e);
            // Return a proper error response instead of letting GlobalExceptionHandler handle it
            BankVerifyResponse errorResponse = BankVerifyResponse.builder()
                    .verified(false)
                    .message(e.getMessage() != null ? e.getMessage() : "Internal server error")
                    .build();
            return ResponseEntity.ok(new ApiResponse<>("Bank verification failed", errorResponse));
        }
    }

    // ==================== Health Check ====================

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("KYC Service is running");
    }

    // ==================== Helper Methods ====================

    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}

