package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.RequestOtpResponse;
import com.krushikranti.fieldofficer.dto.ValidateOtpResponse;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Service for managing OTP requests and validations for farm verification.
 * Handles business logic for OTP generation, notification sending, and validation.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmVerificationOtpManagementService {

    private final FarmVerificationOtpService otpService;
    private final NotificationProducer notificationProducer;
    private final FieldOfficerRepository fieldOfficerRepository;
    private final FieldOfficerAssignmentRepository assignmentRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.farmer-service.url:http://localhost:4000}")
    private String farmerServiceUrl;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    @Value("${farm-verification.otp.expiration:600}")
    private int otpExpirationSeconds;

    /**
     * Request OTP for farm verification.
     * Generates OTP, sends notification to farmer, and stores OTP in Redis.
     */
    @Transactional
    public RequestOtpResponse requestOtp(Long farmId, Long fieldOfficerUserId) {
        log.info("Requesting OTP for farm verification - Farm ID: {}, Field Officer User ID: {}", 
                farmId, fieldOfficerUserId);

        // 1. Validate field officer exists
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        // 2. Validate assignment exists
        FieldOfficerAssignment assignment = assignmentRepository
                .findActiveAssignmentByFieldOfficerAndFarm(fieldOfficer.getId(), farmId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "You are not assigned to farm ID: " + farmId));

        // 3. Get farmer information (userId from assignment)
        Long farmerUserId = assignment.getFarmerUserId();

        // 4. Get farm and farmer details for notification
        Map<String, Object> farmInfo = getFarmInfo(farmId, farmerUserId);
        Map<String, Object> farmerInfo = getFarmerInfo(farmerUserId);
        Map<String, Object> fieldOfficerInfo = getFieldOfficerInfo(fieldOfficerUserId);

        String farmName = (String) farmInfo.getOrDefault("farmName", "Farm " + farmId);
        String farmerPhoneNumber = (String) farmerInfo.getOrDefault("phoneNumber", "");
        String fieldOfficerName = (String) fieldOfficerInfo.getOrDefault("name", 
                fieldOfficerInfo.getOrDefault("username", "Field Officer"));

        // 5. Generate OTP
        String otp = otpService.generateOtp(farmId, farmerUserId, fieldOfficerUserId);

        // 6. Send notification via Kafka (non-blocking - don't fail OTP request if Kafka is down)
        try {
            notificationProducer.sendFarmVerificationOtpNotification(
                    farmerUserId,
                    farmerPhoneNumber,
                    otp,
                    farmId,
                    farmName,
                    fieldOfficerName
            );
            log.info("OTP generated and notification sent - Farm ID: {}, Farmer User ID: {}, OTP: {}", 
                    farmId, farmerUserId, otp);
        } catch (Exception e) {
            // Log error but don't fail the OTP request
            // The OTP is already generated and stored in Redis
            log.error("Failed to send notification to Kafka, but OTP was generated successfully. " +
                    "Farm ID: {}, Farmer User ID: {}, OTP: {}. Error: {}", 
                    farmId, farmerUserId, otp, e.getMessage());
            // Continue - OTP is still valid even if notification fails
        }

        return RequestOtpResponse.builder()
                .farmId(farmId)
                .message("OTP sent successfully to farmer")
                .expiresAt(LocalDateTime.now().plusSeconds(otpExpirationSeconds))
                .expirationMinutes(otpExpirationSeconds / 60)
                .build();
    }

    /**
     * Validate OTP for farm verification.
     */
    @Transactional
    public ValidateOtpResponse validateOtp(Long farmId, String otp, Long fieldOfficerUserId) {
        log.info("Validating OTP for farm verification - Farm ID: {}, Field Officer User ID: {}", 
                farmId, fieldOfficerUserId);

        // 1. Validate field officer exists
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        // 2. Validate assignment exists
        FieldOfficerAssignment assignment = assignmentRepository
                .findActiveAssignmentByFieldOfficerAndFarm(fieldOfficer.getId(), farmId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "You are not assigned to farm ID: " + farmId));

        // 3. Get farmer userId from assignment
        Long farmerUserId = assignment.getFarmerUserId();
        log.info("Assignment details - Assignment ID: {}, Farm ID: {}, Farmer User ID: {}, Field Officer ID: {}", 
                assignment.getId(), farmId, farmerUserId, fieldOfficer.getId());

        // 4. Validate OTP
        log.info("Calling otpService.validateOtp - Farm ID: {}, Farmer User ID: {}, OTP: {}", 
                farmId, farmerUserId, otp);
        boolean isValid = otpService.validateOtp(farmId, farmerUserId, otp);

        if (isValid) {
            String expectedValidationKey = "farm_verification_otp_validated:" + farmId + ":" + farmerUserId;
            log.info("OTP validated successfully - Farm ID: {}, Farmer User ID: {}. Validation key stored in Redis: {}", 
                    farmId, farmerUserId, expectedValidationKey);
            return ValidateOtpResponse.builder()
                    .farmId(farmId)
                    .isValid(true)
                    .message("OTP validated successfully. You can now submit verification.")
                    .build();
        } else {
            log.warn("OTP validation failed - Farm ID: {}, Farmer User ID: {}", 
                    farmId, farmerUserId);
            return ValidateOtpResponse.builder()
                    .farmId(farmId)
                    .isValid(false)
                    .message("Invalid or expired OTP. Please request a new OTP.")
                    .build();
        }
    }

    /**
     * Check if OTP has been validated for this farm verification.
     */
    public boolean isOtpValidated(Long farmId, Long fieldOfficerUserId) {
        log.info("Checking OTP validation status - Farm ID: {}, Field Officer User ID: {}", 
                farmId, fieldOfficerUserId);
        
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        FieldOfficerAssignment assignment = assignmentRepository
                .findActiveAssignmentByFieldOfficerAndFarm(fieldOfficer.getId(), farmId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "You are not assigned to farm ID: " + farmId));

        Long farmerUserId = assignment.getFarmerUserId();
        log.info("Assignment details for validation check - Assignment ID: {}, Farm ID: {}, Farmer User ID: {}, Field Officer ID: {}", 
                assignment.getId(), farmId, farmerUserId, fieldOfficer.getId());
        
        String expectedValidationKey = "farm_verification_otp_validated:" + farmId + ":" + farmerUserId;
        log.info("Checking validation for Farm ID: {}, Farmer User ID: {}, Expected Validation Key: {}", 
                farmId, farmerUserId, expectedValidationKey);
        
        boolean isValid = otpService.isOtpValidated(farmId, farmerUserId);
        log.info("OTP validation check result - Farm ID: {}, Farmer User ID: {}, Validation Key: {}, Is Valid: {}", 
                farmId, farmerUserId, expectedValidationKey, isValid);
        
        return isValid;
    }

    /**
     * Clear OTP rate limit for a farm (useful for testing/resetting)
     */
    public void clearRateLimit(Long farmId, Long fieldOfficerUserId) {
        otpService.clearRateLimit(farmId, fieldOfficerUserId);
    }

    /**
     * Get farm information from farmer-service
     */
    private Map<String, Object> getFarmInfo(Long farmId, Long farmerUserId) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(farmerServiceUrl).build();
            
            // Call farmer-service to get farm details
            // Note: This requires the farmer's userId to be passed
            Map<String, Object> response = webClient.get()
                    .uri("/farmer/profile/farms/{farmId}", farmId)
                    .header("X-User-Id", String.valueOf(farmerUserId))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            // Extract data from ApiResponse wrapper
            if (response != null && response.containsKey("data")) {
                Object data = response.get("data");
                if (data instanceof Map) {
                    return (Map<String, Object>) data;
                }
            }
            
            return response != null ? response : Map.of();
        } catch (Exception e) {
            log.error("Failed to fetch farm info from farmer-service: {}", e.getMessage(), e);
            // Return default values if service call fails
            return Map.of("farmName", "Farm " + farmId, "id", farmId);
        }
    }

    /**
     * Get farmer information from farmer-service
     */
    private Map<String, Object> getFarmerInfo(Long farmerUserId) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(farmerServiceUrl).build();
            
            Map<String, Object> response = webClient.get()
                    .uri("/farmer/profile/my-details")
                    .header("X-User-Id", String.valueOf(farmerUserId))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            // Extract data from ApiResponse wrapper
            if (response != null && response.containsKey("data")) {
                Object data = response.get("data");
                if (data instanceof Map) {
                    return (Map<String, Object>) data;
                }
            }
            
            return response != null ? response : Map.of();
        } catch (Exception e) {
            log.error("Failed to fetch farmer info from farmer-service: {}", e.getMessage(), e);
            // Fallback: get phone from auth-service
            return getFarmerPhoneFromAuth(farmerUserId);
        }
    }

    /**
     * Get farmer phone number from auth-service as fallback
     */
    private Map<String, Object> getFarmerPhoneFromAuth(Long farmerUserId) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(authServiceUrl).build();
            
            Map<String, Object> response = webClient.get()
                    .uri("/auth/user/{userId}", farmerUserId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            // Auth service returns UserInfo directly (not wrapped in ApiResponse)
            if (response != null) {
                return Map.of(
                        "phoneNumber", response.getOrDefault("phoneNumber", ""),
                        "userId", farmerUserId
                );
            }
            
            return Map.of("phoneNumber", "", "userId", farmerUserId);
        } catch (Exception e) {
            log.error("Failed to fetch user info from auth-service: {}", e.getMessage(), e);
            return Map.of("phoneNumber", "", "userId", farmerUserId);
        }
    }

    /**
     * Get field officer information
     */
    private Map<String, Object> getFieldOfficerInfo(Long fieldOfficerUserId) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(authServiceUrl).build();
            
            Map<String, Object> response = webClient.get()
                    .uri("/auth/user/{userId}", fieldOfficerUserId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            // Auth service returns UserInfo directly (not wrapped in ApiResponse)
            if (response != null) {
                String username = (String) response.getOrDefault("username", "Field Officer");
                return Map.of(
                        "name", username,
                        "username", username,
                        "userId", fieldOfficerUserId
                );
            }
            
            return Map.of("name", "Field Officer", "userId", fieldOfficerUserId);
        } catch (Exception e) {
            log.warn("Failed to fetch field officer info from auth-service: {}. Using default name.", e.getMessage());
            // Don't log full stack trace for this - it's not critical
            return Map.of("name", "Field Officer", "userId", fieldOfficerUserId);
        }
    }
}

