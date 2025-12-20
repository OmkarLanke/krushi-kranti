package com.krushikranti.kyc.client;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.krushikranti.kyc.client.dto.*;
import com.krushikranti.kyc.config.QuickEkycConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

/**
 * Client for Quick eKYC API integration.
 * Handles PAN, Aadhaar, and Bank Account verification API calls.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class QuickEkycClient {

    private final WebClient quickEkycWebClient;
    private final QuickEkycConfig quickEkycConfig;
    private final ObjectMapper objectMapper;

    /**
     * Validate PAN number using Quick eKYC API.
     * 
     * @param panNumber The PAN number to validate
     * @return PanValidationResponse with validation result
     */
    public PanValidationResponse validatePan(String panNumber) {
        log.info("Calling Quick eKYC PAN Lite API for PAN: {}XXXX{}", 
                panNumber.substring(0, 5), panNumber.substring(9));
        
        QuickEkycRequest request = QuickEkycRequest.builder()
                .key(quickEkycConfig.getKey())
                .idNumber(panNumber)
                .build();

        try {
            // Using PAN Lite endpoint (/api/v1/pan/pan) for "Pan Verification API (NAME)" subscription
            PanValidationResponse response = quickEkycWebClient.post()
                    .uri("/api/v1/pan/pan")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(PanValidationResponse.class)
                    .block();
            
            log.info("PAN Validation Response - Status: {}, StatusCode: {}, RequestId: {}, Message: {}", 
                    response != null ? response.getStatus() : "null",
                    response != null ? response.getStatusCode() : "null",
                    response != null ? response.getRequestId() : "null",
                    response != null ? response.getMessage() : "null");
            
            if (response != null && "error".equalsIgnoreCase(response.getStatus())) {
                log.warn("QuickeKYC returned error response - StatusCode: {}, Message: {}", 
                        response.getStatusCode(), response.getMessage());
            }
            
            return response;
        } catch (WebClientResponseException e) {
            log.error("Quick eKYC PAN API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("PAN validation failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Error calling Quick eKYC PAN API", e);
            throw new RuntimeException("PAN validation failed: " + e.getMessage(), e);
        }
    }

    /**
     * Generate OTP for Aadhaar verification using Quick eKYC API.
     * 
     * @param aadhaarNumber The Aadhaar number (12 digits)
     * @return AadhaarGenerateOtpResponse with OTP generation result
     */
    public AadhaarGenerateOtpResponse generateAadhaarOtp(String aadhaarNumber) {
        log.info("Calling Quick eKYC Aadhaar Generate OTP API for Aadhaar: XXXXXXXX{}", 
                aadhaarNumber.substring(8));
        
        QuickEkycRequest request = QuickEkycRequest.builder()
                .key(quickEkycConfig.getKey())
                .idNumber(aadhaarNumber)
                .build();

        try {
            log.debug("Sending Aadhaar OTP request to QuickeKYC: key={}, id_number={}",
                    request.getKey(), maskAadhaar(request.getIdNumber()));

            AadhaarGenerateOtpResponse response = quickEkycWebClient.post()
                    .uri("/api/v1/aadhaar-v2/generate-otp")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(AadhaarGenerateOtpResponse.class)
                    .block();
            
            log.info("Aadhaar Generate OTP Response - Status: {}, OTP Sent: {}, RequestId: {}", 
                    response != null ? response.getStatus() : "null",
                    response != null && response.getData() != null ? response.getData().getOtpSent() : "null",
                    response != null ? response.getRequestIdAsString() : "null");
            
            return response;
        } catch (WebClientResponseException e) {
            String errorBody = e.getResponseBodyAsString();
            log.error("Quick eKYC Aadhaar OTP API error - StatusCode: {}, ResponseBody: {}",
                    e.getStatusCode(), errorBody);
            try {
                // Attempt to parse the error body into AadhaarGenerateOtpResponse
                AadhaarGenerateOtpResponse errorResponse = objectMapper.readValue(errorBody, AadhaarGenerateOtpResponse.class);
                return errorResponse;
            } catch (Exception parseEx) {
                log.error("Failed to parse QuickeKYC error response body: {}", errorBody, parseEx);
                AadhaarGenerateOtpResponse errorResponse = new AadhaarGenerateOtpResponse();
                errorResponse.setStatus("error");
                errorResponse.setStatusCode(e.getStatusCode().value());
                errorResponse.setMessage("QuickeKYC API error: " + errorBody);
                return errorResponse;
            }
        } catch (Exception e) {
            log.error("Error calling Quick eKYC Aadhaar OTP API", e);
            log.error("Request URL: {}/api/v1/aadhaar-v2/generate-otp", quickEkycConfig.getBaseUrl());
            log.error("Request Body: key={}, id_number={}", request.getKey(), maskAadhaar(request.getIdNumber()));
            throw new RuntimeException("Aadhaar OTP generation failed: " + e.getMessage(), e);
        }
    }

    /**
     * Submit OTP for Aadhaar verification using Quick eKYC API.
     * 
     * @param requestId The request_id from generateAadhaarOtp response
     * @param otp The OTP entered by user
     * @return AadhaarSubmitOtpResponse with full Aadhaar details on success
     */
    public AadhaarSubmitOtpResponse submitAadhaarOtp(String requestId, String otp) {
        log.info("Calling Quick eKYC Aadhaar Submit OTP API for RequestId: {}", requestId);
        
        AadhaarSubmitOtpRequest request = AadhaarSubmitOtpRequest.builder()
                .key(quickEkycConfig.getKey())
                .requestId(requestId)
                .otp(otp)
                .build();

        try {
            AadhaarSubmitOtpResponse response = quickEkycWebClient.post()
                    .uri("/api/v1/aadhaar-v2/submit-otp")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(AadhaarSubmitOtpResponse.class)
                    .block();
            
            log.info("Aadhaar Submit OTP Response - Status: {}, Name: {}", 
                    response != null ? response.getStatus() : "null",
                    response != null && response.getData() != null ? 
                            maskName(response.getData().getFullName()) : "null");
            
            return response;
        } catch (WebClientResponseException e) {
            log.error("Quick eKYC Aadhaar Submit OTP API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            throw new RuntimeException("Aadhaar OTP verification failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Error calling Quick eKYC Aadhaar Submit OTP API", e);
            throw new RuntimeException("Aadhaar OTP verification failed: " + e.getMessage(), e);
        }
    }

    /**
     * Verify Bank Account using Quick eKYC API.
     * 
     * @param accountNumber The bank account number
     * @param ifscCode The IFSC code of the bank branch
     * @return BankVerificationResponse with verification result
     */
    public BankVerificationResponse verifyBankAccount(String accountNumber, String ifscCode) {
        log.info("Calling Quick eKYC Bank Verification API for Account: XXXXXXXX{}, IFSC: {}", 
                accountNumber.substring(Math.max(0, accountNumber.length() - 4)), ifscCode);
        log.debug("Quick eKYC Base URL: {}, API Key configured: {}", 
                quickEkycConfig.getBaseUrl(), 
                quickEkycConfig.getKey() != null && !quickEkycConfig.getKey().isEmpty());
        
        BankVerificationRequest request = BankVerificationRequest.builder()
                .key(quickEkycConfig.getKey())
                .idNumber(accountNumber)
                .ifsc(ifscCode)
                .build();
        
        log.debug("Bank Verification Request - IFSC: {}, Account Length: {}", ifscCode, accountNumber.length());

        try {
            BankVerificationResponse response = quickEkycWebClient.post()
                    .uri("/api/v1/bank-verification")
                    .bodyValue(request)
                    .retrieve()
                    .onStatus(status -> status.is4xxClientError() || status.is5xxServerError(), 
                            clientResponse -> {
                                log.error("Quick eKYC Bank API error: {} - {}", 
                                        clientResponse.statusCode(), 
                                        clientResponse.statusCode().value());
                                return clientResponse.bodyToMono(String.class)
                                        .flatMap(body -> {
                                            log.error("Error response body: {}", body);
                                            return Mono.error(new RuntimeException("Quick eKYC API error: " + 
                                                    clientResponse.statusCode() + " - " + body));
                                        })
                                        .cast(Throwable.class);
                            })
                    .bodyToMono(BankVerificationResponse.class)
                    .block();
            
            if (response == null) {
                log.error("Quick eKYC Bank API returned null response");
                throw new RuntimeException("Bank verification failed: API returned null response");
            }
            
            log.info("Bank Verification Response - Status: {}, StatusCode: {}, Message: {}, Account Exists: {}, Name: {}, RequestId: {}", 
                    response.getStatus(),
                    response.getStatusCode(),
                    response.getMessage(),
                    response.getData() != null ? response.getData().getAccountExists() : "null",
                    response.getData() != null ? 
                            maskName(response.getData().getFullName()) : "null",
                    response.getRequestId());
            
            return response;
        } catch (WebClientResponseException e) {
            String errorBody = e.getResponseBodyAsString();
            log.error("Quick eKYC Bank API HTTP error: {} - Response: {}", e.getStatusCode(), errorBody);
            throw new RuntimeException("Bank verification failed: " + e.getStatusCode() + 
                    (errorBody != null && !errorBody.isEmpty() ? " - " + errorBody : ""), e);
        } catch (RuntimeException e) {
            // Re-throw RuntimeExceptions as-is
            throw e;
        } catch (Exception e) {
            log.error("Error calling Quick eKYC Bank API", e);
            String errorMessage = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            throw new RuntimeException("Bank verification failed: " + errorMessage, e);
        }
    }
    
    /**
     * Mask Aadhaar number for logging (privacy protection)
     */
    private String maskAadhaar(String aadhaar) {
        if (aadhaar == null || aadhaar.length() != 12) return aadhaar;
        return "XXXX XXXX " + aadhaar.substring(8);
    }
    
    /**
     * Mask name for logging (privacy protection)
     */
    private String maskName(String name) {
        if (name == null || name.length() < 3) return "***";
        return name.substring(0, 2) + "***" + name.substring(name.length() - 1);
    }
}

