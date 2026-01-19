package com.krushikranti.fieldofficer.controller;

import com.krushikranti.fieldofficer.dto.ApiResponse;
import com.krushikranti.fieldofficer.dto.AssignmentResponseDto;
import com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto;
import com.krushikranti.fieldofficer.dto.RequestOtpRequest;
import com.krushikranti.fieldofficer.dto.RequestOtpResponse;
import com.krushikranti.fieldofficer.dto.ValidateOtpRequest;
import com.krushikranti.fieldofficer.dto.ValidateOtpResponse;
import com.krushikranti.fieldofficer.dto.VerificationPhotoDto;
import com.krushikranti.fieldofficer.dto.VerifyFarmRequest;
import com.krushikranti.fieldofficer.dto.VerifyFarmResponse;
import com.krushikranti.fieldofficer.service.FarmVerificationService;
import com.krushikranti.fieldofficer.service.FarmVerificationOtpManagementService;
import com.krushikranti.fieldofficer.service.FieldOfficerAssignmentService;
import com.krushikranti.fieldofficer.service.FieldOfficerProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Field Officer facing controller for their own operations.
 */
@RestController
@RequestMapping("/field-officer")
@RequiredArgsConstructor
@Slf4j
public class FieldOfficerController {

    private final FieldOfficerProfileService fieldOfficerProfileService;
    private final FieldOfficerAssignmentService assignmentService;
    private final FarmVerificationService verificationService;
    private final FarmVerificationOtpManagementService otpManagementService;

    /**
     * Get field officer's own profile
     */
    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<Object>> getProfile(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @RequestHeader(value = "X-User-Roles", required = false) String rolesHeader) {
        try {
            // Check if X-User-Id header is present
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header. This indicates API Gateway authentication issue.");
                log.error("Request headers - X-User-Id: {}, X-User-Roles: {}", userIdHeader, rolesHeader);
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification. Please login again.", null));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            log.debug("Fetching profile for field officer userId: {} with roles: {}", userId, rolesHeader);
            
            Map<String, Object> profile = fieldOfficerProfileService.getProfile(userId);
            return ResponseEntity.ok(new ApiResponse<>("Profile retrieved successfully", profile));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (RuntimeException e) {
            log.error("Error retrieving profile for userId {}: {}", userIdHeader, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Unexpected error retrieving profile: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Field Officer Service is running");
    }

    /**
     * Get assignments for the logged-in field officer with farm details.
     */
    @GetMapping("/assignments")
    public ResponseEntity<ApiResponse<List<FieldOfficerAssignmentDto>>> getAssignments(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for assignments request");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            log.info("Fetching assignments for field officer userId: {}", userId);
            
            List<FieldOfficerAssignmentDto> assignments = assignmentService.getAssignmentsWithFarmsForFieldOfficer(userId);
            
            log.info("Successfully retrieved {} assignments for field officer userId: {}", assignments.size(), userId);
            return ResponseEntity.ok(new ApiResponse<>("Assignments retrieved successfully", assignments));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (IllegalArgumentException e) {
            log.error("Invalid request: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Unexpected error retrieving assignments for userId {}: {}", userIdHeader, e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Test endpoint to verify API Gateway authentication
     * Returns the headers received from API Gateway
     */
    @GetMapping("/test-auth")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testAuth(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @RequestHeader(value = "X-User-Roles", required = false) String rolesHeader,
            @RequestHeader(value = "X-Username", required = false) String usernameHeader,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Map<String, Object> headers = new java.util.HashMap<>();
        headers.put("X-User-Id", userIdHeader != null ? userIdHeader : "MISSING");
        headers.put("X-User-Roles", rolesHeader != null ? rolesHeader : "MISSING");
        headers.put("X-Username", usernameHeader != null ? usernameHeader : "MISSING");
        headers.put("Authorization-Present", authHeader != null && !authHeader.isEmpty());
        
        log.info("Test auth endpoint called - Headers: {}", headers);
        
        return ResponseEntity.ok(new ApiResponse<>("Authentication test", headers));
    }

    /**
     * Verify or reject a farm.
     * Field officer can verify or reject farms assigned to them.
     */
    @PostMapping("/verify-farm")
    public ResponseEntity<ApiResponse<VerifyFarmResponse>> verifyFarm(
            @Valid @RequestBody VerifyFarmRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for verify farm request");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            Long userId = Long.parseLong(userIdHeader.trim());
            log.info("Farm verification request - Farm ID: {}, Status: {}, Field Officer User ID: {}", 
                    request.getFarmId(), request.getStatus(), userId);

            VerifyFarmResponse response = verificationService.verifyFarm(request, userId);

            return ResponseEntity.ok(new ApiResponse<>(
                    "Farm verification " + (request.getStatus().equalsIgnoreCase("VERIFIED") ? "completed" : "recorded") + " successfully",
                    response));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (IllegalArgumentException e) {
            log.warn("Invalid verification request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Error verifying farm: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Get verification status for a specific farm.
     */
    @GetMapping("/verify-farm/{farmId}")
    public ResponseEntity<ApiResponse<VerifyFarmResponse>> getVerification(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for get verification request");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            Long userId = Long.parseLong(userIdHeader.trim());
            log.info("Getting verification for farm ID: {} by field officer userId: {}", farmId, userId);

            Optional<VerifyFarmResponse> verification = verificationService.getVerification(farmId, userId);

            if (verification.isPresent()) {
                return ResponseEntity.ok(new ApiResponse<>("Verification retrieved successfully", verification.get()));
            } else {
                return ResponseEntity.ok(new ApiResponse<>("No verification found for this farm", null));
            }
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (IllegalArgumentException e) {
            log.warn("Invalid request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Error getting verification: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Get field officer assignments for the logged-in farmer.
     * This endpoint allows farmers to see which field officers are assigned to their farms.
     */
    @GetMapping("/farmer/assignments")
    public ResponseEntity<ApiResponse<List<AssignmentResponseDto>>> getFarmerAssignments(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for farmer assignments request");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }
            
            Long farmerUserId = Long.parseLong(userIdHeader.trim());
            log.info("Fetching field officer assignments for farmer userId: {}", farmerUserId);
            
            List<AssignmentResponseDto> assignments = assignmentService.getAssignmentsForFarmer(farmerUserId);
            
            log.info("Successfully retrieved {} assignments for farmer userId: {}", assignments.size(), farmerUserId);
            return ResponseEntity.ok(new ApiResponse<>("Assignments retrieved successfully", assignments));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (Exception e) {
            log.error("Unexpected error retrieving farmer assignments for userId {}: {}", userIdHeader, e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Request OTP for farm verification.
     * Generates OTP and sends notification to farmer.
     */
    @PostMapping("/farms/{farmId}/request-otp")
    public ResponseEntity<ApiResponse<com.krushikranti.fieldofficer.dto.RequestOtpResponse>> requestOtp(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for request OTP");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            Long fieldOfficerUserId = Long.parseLong(userIdHeader.trim());
            log.info("Requesting OTP for farm verification - Farm ID: {}, Field Officer User ID: {}", 
                    farmId, fieldOfficerUserId);

            RequestOtpResponse response = 
                    otpManagementService.requestOtp(farmId, fieldOfficerUserId);

            return ResponseEntity.ok(new ApiResponse<>("OTP sent successfully to farmer", response));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (IllegalArgumentException e) {
            log.warn("Invalid OTP request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (IllegalStateException e) {
            // Rate limit exceeded or similar state errors
            log.warn("OTP request failed due to state: {}", e.getMessage());
            return ResponseEntity.status(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS)
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Error requesting OTP: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Validate OTP for farm verification.
     */
    @PostMapping("/farms/{farmId}/validate-otp")
    public ResponseEntity<ApiResponse<com.krushikranti.fieldofficer.dto.ValidateOtpResponse>> validateOtp(
            @PathVariable Long farmId,
            @Valid @RequestBody com.krushikranti.fieldofficer.dto.ValidateOtpRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for validate OTP");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            // Validate farmId matches request
            if (!farmId.equals(request.getFarmId())) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("Farm ID in path does not match request body", null));
            }

            Long fieldOfficerUserId = Long.parseLong(userIdHeader.trim());
            log.info("Validating OTP for farm verification - Farm ID: {}, Field Officer User ID: {}", 
                    farmId, fieldOfficerUserId);

            ValidateOtpResponse response = 
                    otpManagementService.validateOtp(farmId, request.getOtp(), fieldOfficerUserId);

            if (response.isValid()) {
                return ResponseEntity.ok(new ApiResponse<>("OTP validated successfully", response));
            } else {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>(response.getMessage(), response));
            }
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (IllegalArgumentException e) {
            log.warn("Invalid OTP validation request: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Error validating OTP: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Clear OTP rate limit for a farm (useful for testing/resetting)
     */
    @DeleteMapping("/farms/{farmId}/otp-rate-limit")
    public ResponseEntity<ApiResponse<String>> clearOtpRateLimit(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            Long fieldOfficerUserId = Long.parseLong(userIdHeader.trim());
            otpManagementService.clearRateLimit(farmId, fieldOfficerUserId);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "Rate limit cleared successfully for farm " + farmId, 
                    "Rate limit reset. You can now request OTP again."));
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (Exception e) {
            log.error("Error clearing rate limit: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Debug endpoint to check OTP validation status
     */
    @GetMapping("/farms/{farmId}/otp-validation-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkOtpValidationStatus(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }

            Long fieldOfficerUserId = Long.parseLong(userIdHeader.trim());
            log.info("=== DEBUG: Checking OTP validation status for Farm ID: {}, Field Officer User ID: {} ===", 
                    farmId, fieldOfficerUserId);
            
            boolean isValid = otpManagementService.isOtpValidated(farmId, fieldOfficerUserId);
            
            Map<String, Object> status = new java.util.HashMap<>();
            status.put("farmId", farmId);
            status.put("fieldOfficerUserId", fieldOfficerUserId);
            status.put("isOtpValidated", isValid);
            
            log.info("=== DEBUG: OTP validation status result: {} for Farm ID: {}, Field Officer User ID: {} ===", 
                    isValid, farmId, fieldOfficerUserId);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    "OTP validation status checked", status));
        } catch (Exception e) {
            log.error("Error checking OTP validation status: {}", e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }

    /**
     * Get verification photos for a farm.
     * Returns all geo-tagged photos taken during farm verification.
     */
    @GetMapping("/verifications/farms/{farmId}/photos")
    public ResponseEntity<ApiResponse<List<VerificationPhotoDto>>> getVerificationPhotos(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("Missing X-User-Id header for verification photos request");
                return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>("Unauthorized: Missing user identification", null));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            log.info("Fetching verification photos for farm ID: {} by field officer userId: {}", farmId, userId);
            
            List<VerificationPhotoDto> photos = verificationService.getVerificationPhotosByFarmId(farmId);
            return ResponseEntity.ok(new ApiResponse<>("Verification photos retrieved successfully", photos));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format: " + userIdHeader, null));
        } catch (Exception e) {
            log.error("Error retrieving verification photos for farm ID {}: {}", farmId, e.getMessage(), e);
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("An unexpected error occurred: " + e.getMessage(), null));
        }
    }
}

