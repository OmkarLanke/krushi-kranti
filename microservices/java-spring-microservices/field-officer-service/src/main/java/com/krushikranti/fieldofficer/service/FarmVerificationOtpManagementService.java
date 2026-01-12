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

        // 6. Send notification via Kafka
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

        // 4. Validate OTP
        boolean isValid = otpService.validateOtp(farmId, farmerUserId, otp);

        if (isValid) {
            log.info("OTP validated successfully - Farm ID: {}, Farmer User ID: {}", 
                    farmId, farmerUserId);
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
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        FieldOfficerAssignment assignment = assignmentRepository
                .findActiveAssignmentByFieldOfficerAndFarm(fieldOfficer.getId(), farmId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "You are not assigned to farm ID: " + farmId));

        Long farmerUserId = assignment.getFarmerUserId();
        return otpService.isOtpValidated(farmId, farmerUserId);
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
                    .uri("/auth/users/{userId}", farmerUserId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            if (response != null && response.containsKey("data")) {
                Object data = response.get("data");
                if (data instanceof Map) {
                    Map<String, Object> userData = (Map<String, Object>) data;
                    return Map.of(
                            "phoneNumber", userData.getOrDefault("phoneNumber", ""),
                            "userId", farmerUserId
                    );
                }
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
                    .uri("/auth/users/{userId}", fieldOfficerUserId)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            if (response != null && response.containsKey("data")) {
                Object data = response.get("data");
                if (data instanceof Map) {
                    Map<String, Object> userData = (Map<String, Object>) data;
                    return Map.of(
                            "name", userData.getOrDefault("username", "Field Officer"),
                            "username", userData.getOrDefault("username", ""),
                            "userId", fieldOfficerUserId
                    );
                }
            }
            
            return Map.of("name", "Field Officer", "userId", fieldOfficerUserId);
        } catch (Exception e) {
            log.error("Failed to fetch field officer info from auth-service: {}", e.getMessage(), e);
            return Map.of("name", "Field Officer", "userId", fieldOfficerUserId);
        }
    }
}

