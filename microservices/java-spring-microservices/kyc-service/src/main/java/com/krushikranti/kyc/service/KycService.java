package com.krushikranti.kyc.service;

import com.krushikranti.kyc.client.QuickEkycClient;
import com.krushikranti.kyc.client.dto.AadhaarSubmitOtpResponse;
import com.krushikranti.kyc.client.dto.BankVerificationResponse;
import com.krushikranti.kyc.client.dto.PanValidationResponse;
import com.krushikranti.kyc.dto.*;
import com.krushikranti.kyc.model.*;
import com.krushikranti.kyc.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;

/**
 * Service for KYC verification operations.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KycService {

    private final KycVerificationRepository kycVerificationRepository;
    private final KycVerificationLogRepository kycVerificationLogRepository;
    private final AadhaarOtpSessionRepository aadhaarOtpSessionRepository;
    private final QuickEkycClient quickEkycClient;

    /**
     * Get KYC status for a user.
     */
    @Transactional(readOnly = true)
    public KycStatusResponse getKycStatus(Long userId) {
        log.info("Getting KYC status for userId: {}", userId);
        
        KycVerification kyc = kycVerificationRepository.findByUserId(userId)
                .orElse(KycVerification.builder()
                        .userId(userId)
                        .kycStatus(KycStatus.PENDING)
                        .aadhaarVerified(false)
                        .panVerified(false)
                        .bankVerified(false)
                        .build());
        
        return KycStatusResponse.builder()
                .userId(kyc.getUserId())
                .kycStatus(kyc.getKycStatus())
                .aadhaarVerified(kyc.getAadhaarVerified())
                .aadhaarNumberMasked(kyc.getAadhaarNumberMasked())
                .aadhaarName(kyc.getAadhaarName())
                .aadhaarVerifiedAt(kyc.getAadhaarVerifiedAt())
                .panVerified(kyc.getPanVerified())
                .panNumberMasked(kyc.getPanNumberMasked())
                .panName(kyc.getPanName())
                .panVerifiedAt(kyc.getPanVerifiedAt())
                .bankVerified(kyc.getBankVerified())
                .bankAccountMasked(kyc.getBankAccountMasked())
                .bankIfsc(kyc.getBankIfsc())
                .bankName(kyc.getBankName())
                .bankAccountHolderName(kyc.getBankAccountHolderName())
                .bankVerifiedAt(kyc.getBankVerifiedAt())
                .build();
    }

    /**
     * Verify PAN number.
     */
    @Transactional
    public PanVerifyResponse verifyPan(Long userId, String panNumber, String ipAddress) {
        log.info("Verifying PAN for userId: {}", userId);
        
        // Get or create KYC record
        KycVerification kyc = getOrCreateKycVerification(userId);
        
        // Check if already verified
        if (Boolean.TRUE.equals(kyc.getPanVerified())) {
            return PanVerifyResponse.builder()
                    .verified(true)
                    .panNumberMasked(kyc.getPanNumberMasked())
                    .name(kyc.getPanName())
                    .message("PAN already verified")
                    .build();
        }
        
        try {
            // Call Quick eKYC API
            PanValidationResponse response = quickEkycClient.validatePan(panNumber);
            
            // Log the verification attempt
            logVerificationAttempt(userId, VerificationType.PAN, 
                    response.getRequestIdAsString(), 
                    response.isSuccess() ? LogStatus.SUCCESS : LogStatus.FAILED,
                    response.isSuccess() ? null : response.getMessage(),
                    "PAN: " + maskPan(panNumber),
                    "Status: " + response.getStatus(),
                    ipAddress);
            
            if (response.isSuccess() && response.getData() != null && 
                Boolean.TRUE.equals(response.getData().getIsValid())) {
                
                // Update KYC record
                kyc.setPanVerified(true);
                kyc.setPanNumberMasked(maskPan(panNumber));
                kyc.setPanName(response.getData().getFullName());
                kyc.setPanVerifiedAt(LocalDateTime.now());
                kycVerificationRepository.save(kyc);
                
                return PanVerifyResponse.builder()
                        .verified(true)
                        .panNumberMasked(maskPan(panNumber))
                        .name(response.getData().getFullName())
                        .message("PAN verified successfully")
                        .build();
            } else {
                return PanVerifyResponse.builder()
                        .verified(false)
                        .message(response.getMessage() != null ? response.getMessage() : "PAN validation failed")
                        .build();
            }
        } catch (Exception e) {
            log.error("PAN verification failed for userId: {}", userId, e);
            logVerificationAttempt(userId, VerificationType.PAN, null, LogStatus.FAILED,
                    e.getMessage(), "PAN: " + maskPan(panNumber), null, ipAddress);
            throw new RuntimeException("PAN verification failed: " + e.getMessage(), e);
        }
    }

    /**
     * Generate OTP for Aadhaar verification.
     */
    @Transactional
    public AadhaarGenerateOtpResponse generateAadhaarOtp(Long userId, String aadhaarNumber, String ipAddress) {
        log.info("Generating Aadhaar OTP for userId: {}", userId);
        
        // Get or create KYC record
        KycVerification kyc = getOrCreateKycVerification(userId);
        
        // Check if already verified
        if (Boolean.TRUE.equals(kyc.getAadhaarVerified())) {
            return AadhaarGenerateOtpResponse.builder()
                    .otpSent(false)
                    .message("Aadhaar already verified")
                    .build();
        }
        
        try {
            // Call Quick eKYC API
            com.krushikranti.kyc.client.dto.AadhaarGenerateOtpResponse response = 
                    quickEkycClient.generateAadhaarOtp(aadhaarNumber);
            
            // Log the verification attempt
            logVerificationAttempt(userId, VerificationType.AADHAAR,
                    response.getRequestIdAsString(),
                    response.isSuccess() ? LogStatus.PENDING : LogStatus.FAILED,
                    response.isSuccess() ? null : response.getMessage(),
                    "Aadhaar: " + maskAadhaar(aadhaarNumber),
                    "OTP Generation - Status: " + response.getStatus(),
                    ipAddress);
            
            if (response.isSuccess() && response.getData() != null && 
                Boolean.TRUE.equals(response.getData().getOtpSent())) {
                
                // Store OTP session
                AadhaarOtpSession session = AadhaarOtpSession.builder()
                        .userId(userId)
                        .aadhaarNumberHash(hashAadhaar(aadhaarNumber))
                        .clientId(response.getData().getClientId())
                        .requestId(response.getRequestIdAsString())
                        .otpSent(true)
                        .expiresAt(LocalDateTime.now().plusMinutes(10)) // OTP valid for 10 minutes
                        .build();
                aadhaarOtpSessionRepository.save(session);
                
                return AadhaarGenerateOtpResponse.builder()
                        .otpSent(true)
                        .requestId(response.getRequestIdAsString())
                        .message("OTP sent to Aadhaar linked mobile")
                        .build();
            } else {
                return AadhaarGenerateOtpResponse.builder()
                        .otpSent(false)
                        .message(response.getMessage() != null ? response.getMessage() : "Failed to generate OTP")
                        .build();
            }
        } catch (Exception e) {
            log.error("Aadhaar OTP generation failed for userId: {}", userId, e);
            logVerificationAttempt(userId, VerificationType.AADHAAR, null, LogStatus.FAILED,
                    e.getMessage(), "Aadhaar: " + maskAadhaar(aadhaarNumber), null, ipAddress);
            throw new RuntimeException("Aadhaar OTP generation failed: " + e.getMessage(), e);
        }
    }

    /**
     * Verify Aadhaar OTP.
     */
    @Transactional
    public AadhaarVerifyOtpResponse verifyAadhaarOtp(Long userId, String requestId, String otp, String ipAddress) {
        log.info("Verifying Aadhaar OTP for userId: {}, requestId: {}", userId, requestId);
        
        // Get KYC record
        KycVerification kyc = getOrCreateKycVerification(userId);
        
        // Check if already verified
        if (Boolean.TRUE.equals(kyc.getAadhaarVerified())) {
            return AadhaarVerifyOtpResponse.builder()
                    .verified(true)
                    .aadhaarNumberMasked(kyc.getAadhaarNumberMasked())
                    .name(kyc.getAadhaarName())
                    .message("Aadhaar already verified")
                    .build();
        }
        
        // Validate OTP session
        AadhaarOtpSession session = aadhaarOtpSessionRepository
                .findByUserIdAndRequestIdAndOtpVerifiedFalse(userId, requestId)
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired OTP session"));
        
        if (session.isExpired()) {
            throw new IllegalArgumentException("OTP session has expired. Please request a new OTP.");
        }
        
        try {
            // Call Quick eKYC API
            AadhaarSubmitOtpResponse response = quickEkycClient.submitAadhaarOtp(requestId, otp);
            
            // Log the verification attempt
            logVerificationAttempt(userId, VerificationType.AADHAAR,
                    requestId,
                    response.isSuccess() ? LogStatus.SUCCESS : LogStatus.FAILED,
                    response.isSuccess() ? null : response.getMessage(),
                    "OTP Verification",
                    "Status: " + response.getStatus(),
                    ipAddress);
            
            if (response.isSuccess() && response.getData() != null) {
                AadhaarSubmitOtpResponse.AadhaarData data = response.getData();
                
                // Update OTP session
                session.setOtpVerified(true);
                aadhaarOtpSessionRepository.save(session);
                
                // Parse DOB
                LocalDate dob = null;
                if (data.getDob() != null && !data.getDob().isEmpty()) {
                    try {
                        dob = LocalDate.parse(data.getDob(), DateTimeFormatter.ofPattern("dd-MM-yyyy"));
                    } catch (Exception e) {
                        log.warn("Failed to parse DOB: {}", data.getDob());
                    }
                }
                
                // Get address
                String address = data.getAddress() != null ? data.getAddress().getFullAddress() : null;
                
                // Update KYC record
                kyc.setAadhaarVerified(true);
                kyc.setAadhaarNumberMasked(maskAadhaar(data.getAadhaarNumber()));
                kyc.setAadhaarName(data.getFullName());
                kyc.setAadhaarDob(dob);
                kyc.setAadhaarGender(data.getGender());
                kyc.setAadhaarAddress(address);
                kyc.setAadhaarVerifiedAt(LocalDateTime.now());
                kycVerificationRepository.save(kyc);
                
                return AadhaarVerifyOtpResponse.builder()
                        .verified(true)
                        .aadhaarNumberMasked(maskAadhaar(data.getAadhaarNumber()))
                        .name(data.getFullName())
                        .dob(data.getDob())
                        .gender(data.getGender())
                        .address(address)
                        .message("Aadhaar verified successfully")
                        .build();
            } else {
                return AadhaarVerifyOtpResponse.builder()
                        .verified(false)
                        .message(response.getMessage() != null ? response.getMessage() : "OTP verification failed")
                        .build();
            }
        } catch (Exception e) {
            log.error("Aadhaar OTP verification failed for userId: {}", userId, e);
            logVerificationAttempt(userId, VerificationType.AADHAAR, requestId, LogStatus.FAILED,
                    e.getMessage(), "OTP Verification", null, ipAddress);
            throw new RuntimeException("Aadhaar OTP verification failed: " + e.getMessage(), e);
        }
    }

    /**
     * Verify Bank Account.
     */
    @Transactional
    public BankVerifyResponse verifyBankAccount(Long userId, String accountNumber, String ifscCode, String ipAddress) {
        log.info("Verifying Bank Account for userId: {}", userId);
        
        // Get or create KYC record
        KycVerification kyc = getOrCreateKycVerification(userId);
        
        // Check if already verified
        if (Boolean.TRUE.equals(kyc.getBankVerified())) {
            return BankVerifyResponse.builder()
                    .verified(true)
                    .accountNumberMasked(kyc.getBankAccountMasked())
                    .ifscCode(kyc.getBankIfsc())
                    .accountHolderName(kyc.getBankAccountHolderName())
                    .bankName(kyc.getBankName())
                    .message("Bank account already verified")
                    .build();
        }
        
        try {
            // Call Quick eKYC API
            BankVerificationResponse response = quickEkycClient.verifyBankAccount(accountNumber, ifscCode);
            
            // Log the verification attempt
            logVerificationAttempt(userId, VerificationType.BANK,
                    response.getRequestId() != null ? String.valueOf(response.getRequestId()) : null,
                    response.isSuccess() ? LogStatus.SUCCESS : LogStatus.FAILED,
                    response.isSuccess() ? null : response.getMessage(),
                    "Account: " + maskAccountNumber(accountNumber) + ", IFSC: " + ifscCode,
                    "Status: " + response.getStatus(),
                    ipAddress);
            
            // Log detailed response for debugging
            if (!response.isSuccess()) {
                log.warn("Bank verification failed - Status: {}, StatusCode: {}, Message: {}, RequestId: {}", 
                        response.getStatus(), 
                        response.getStatusCode(), 
                        response.getMessage(),
                        response.getRequestId());
            }
            
            if (response.isSuccess() && response.getData() != null && 
                Boolean.TRUE.equals(response.getData().getAccountExists())) {
                
                BankVerificationResponse.BankData data = response.getData();
                String bankName = data.getIfscDetails() != null ? data.getIfscDetails().getBank() : null;
                
                // Update KYC record
                kyc.setBankVerified(true);
                kyc.setBankAccountMasked(maskAccountNumber(accountNumber));
                kyc.setBankIfsc(ifscCode);
                kyc.setBankAccountHolderName(data.getFullName());
                kyc.setBankName(bankName);
                kyc.setBankVerifiedAt(LocalDateTime.now());
                kycVerificationRepository.save(kyc);
                
                return BankVerifyResponse.builder()
                        .verified(true)
                        .accountNumberMasked(maskAccountNumber(accountNumber))
                        .ifscCode(ifscCode)
                        .accountHolderName(data.getFullName())
                        .bankName(bankName)
                        .message("Bank account verified successfully")
                        .build();
            } else {
                // Build detailed error message
                StringBuilder errorMessage = new StringBuilder();
                if (response.getMessage() != null && !response.getMessage().isEmpty()) {
                    errorMessage.append(response.getMessage());
                } else {
                    errorMessage.append("Bank verification failed");
                }
                
                // Add status code if available
                if (response.getStatusCode() != null && response.getStatusCode() != 200) {
                    errorMessage.append(" (Status Code: ").append(response.getStatusCode()).append(")");
                }
                
                // Add status if it's an error
                if ("error".equalsIgnoreCase(response.getStatus())) {
                    if (response.getData() != null && response.getData().getRemarks() != null) {
                        errorMessage.append(" - ").append(response.getData().getRemarks());
                    }
                }
                
                log.warn("Bank verification failed for userId: {} - {}", userId, errorMessage.toString());
                
                return BankVerifyResponse.builder()
                        .verified(false)
                        .message(errorMessage.toString())
                        .build();
            }
        } catch (Exception e) {
            log.error("Bank verification failed for userId: {}", userId, e);
            logVerificationAttempt(userId, VerificationType.BANK, null, LogStatus.FAILED,
                    e.getMessage(), "Account: " + maskAccountNumber(accountNumber) + ", IFSC: " + ifscCode, 
                    null, ipAddress);
            throw new RuntimeException("Bank verification failed: " + e.getMessage(), e);
        }
    }

    /**
     * Check if user has completed all KYC verifications.
     */
    public boolean isKycComplete(Long userId) {
        return kycVerificationRepository.findByUserId(userId)
                .map(kyc -> Boolean.TRUE.equals(kyc.getAadhaarVerified()) &&
                           Boolean.TRUE.equals(kyc.getPanVerified()) &&
                           Boolean.TRUE.equals(kyc.getBankVerified()))
                .orElse(false);
    }

    // ==================== Helper Methods ====================

    private KycVerification getOrCreateKycVerification(Long userId) {
        return kycVerificationRepository.findByUserId(userId)
                .orElseGet(() -> {
                    KycVerification newKyc = KycVerification.builder()
                            .userId(userId)
                            .build();
                    return kycVerificationRepository.save(newKyc);
                });
    }

    private void logVerificationAttempt(Long userId, VerificationType type, String requestId,
                                        LogStatus status, String errorMessage, String requestPayload,
                                        String responsePayload, String ipAddress) {
        KycVerificationLog log = KycVerificationLog.builder()
                .userId(userId)
                .verificationType(type)
                .requestId(requestId)
                .status(status)
                .errorMessage(errorMessage)
                .requestPayload(requestPayload)
                .responsePayload(responsePayload)
                .ipAddress(ipAddress)
                .build();
        kycVerificationLogRepository.save(log);
    }

    private String maskPan(String pan) {
        if (pan == null || pan.length() != 10) return pan;
        return pan.substring(0, 5) + "****" + pan.substring(9);
    }

    private String maskAadhaar(String aadhaar) {
        if (aadhaar == null || aadhaar.length() != 12) return aadhaar;
        return "XXXX XXXX " + aadhaar.substring(8);
    }

    private String maskAccountNumber(String accountNumber) {
        if (accountNumber == null || accountNumber.length() < 4) return accountNumber;
        return "X".repeat(accountNumber.length() - 4) + accountNumber.substring(accountNumber.length() - 4);
    }

    private String hashAadhaar(String aadhaar) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(aadhaar.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Failed to hash Aadhaar", e);
        }
    }
}

