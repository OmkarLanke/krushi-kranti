package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.VerifyFarmRequest;
import com.krushikranti.fieldofficer.dto.VerifyFarmResponse;
import com.krushikranti.fieldofficer.model.FarmVerification;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.model.VerificationPhoto;
import com.krushikranti.fieldofficer.repository.FarmVerificationRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import com.krushikranti.fieldofficer.repository.VerificationPhotoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.BodyInserters;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service for farm verification operations.
 * Handles verification of farms by field officers.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmVerificationService {

    private final FarmVerificationRepository verificationRepository;
    private final FieldOfficerRepository fieldOfficerRepository;
    private final FieldOfficerAssignmentRepository assignmentRepository;
    private final VerificationPhotoRepository photoRepository;
    private final FarmVerificationOtpManagementService otpManagementService;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.farmer-service.url:http://localhost:4000}")
    private String farmerServiceUrl;

    /**
     * Verify or reject a farm.
     * Validates that the field officer is assigned to the farm before allowing verification.
     */
    @Transactional
    public VerifyFarmResponse verifyFarm(VerifyFarmRequest request, Long fieldOfficerUserId) {
        log.info("Verifying farm {} by field officer userId {} with status: {}", 
                request.getFarmId(), fieldOfficerUserId, request.getStatus());

        // Validation 1: Find field officer by userId
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        // Validation 2: Check if field officer is assigned to this farm
        Optional<FieldOfficerAssignment> assignmentOpt = 
                assignmentRepository.findActiveAssignmentByFieldOfficerAndFarm(
                        fieldOfficer.getId(), request.getFarmId());

        if (assignmentOpt.isEmpty()) {
            throw new IllegalArgumentException(
                    "You are not assigned to farm ID: " + request.getFarmId() + 
                    ". Only assigned field officers can verify farms.");
        }

        // Validation 3: Validate status
        FarmVerification.VerificationStatus status;
        try {
            status = FarmVerification.VerificationStatus.valueOf(request.getStatus().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                    "Invalid verification status: " + request.getStatus() + 
                    ". Valid values are: VERIFIED, REJECTED, PENDING, IN_PROGRESS");
        }

        // Validation 4: If rejected, rejection reason or feedback should be provided
        if (status == FarmVerification.VerificationStatus.REJECTED) {
            if ((request.getRejectionReason() == null || request.getRejectionReason().trim().isEmpty()) &&
                (request.getFeedback() == null || request.getFeedback().trim().isEmpty())) {
                throw new IllegalArgumentException(
                        "Rejection reason or feedback is required when rejecting a farm.");
            }
        }

        // Validation 5: If VERIFIED, photo URLs are required
        if (status == FarmVerification.VerificationStatus.VERIFIED) {
            if (request.getPhotoUrls() == null || request.getPhotoUrls().isEmpty()) {
                throw new IllegalArgumentException(
                        "At least one geotagged photo is required for farm verification.");
            }
            
            // Validation 6: If VERIFIED, OTP must be validated
            log.info("=== VERIFICATION SUBMISSION: Checking OTP validation for Farm ID: {}, Field Officer User ID: {} ===", 
                    request.getFarmId(), fieldOfficerUserId);
            boolean isOtpValid = otpManagementService.isOtpValidated(request.getFarmId(), fieldOfficerUserId);
            log.info("=== VERIFICATION SUBMISSION: OTP validation check result: {} for Farm ID: {}, Field Officer User ID: {} ===", 
                    isOtpValid, request.getFarmId(), fieldOfficerUserId);
            
            if (!isOtpValid) {
                log.error("=== VERIFICATION SUBMISSION FAILED: OTP not validated for Farm ID: {}, Field Officer User ID: {} ===", 
                        request.getFarmId(), fieldOfficerUserId);
                throw new IllegalArgumentException(
                        "OTP validation is required before submitting farm verification. " +
                        "Please request and validate OTP first.");
            }
            log.info("=== VERIFICATION SUBMISSION: OTP validation passed for Farm ID: {}, Field Officer User ID: {} ===", 
                    request.getFarmId(), fieldOfficerUserId);
        }

        // Check if verification already exists
        Optional<FarmVerification> existingVerification = 
                verificationRepository.findByFarmIdAndFieldOfficerId(
                        request.getFarmId(), fieldOfficer.getId());

        FarmVerification verification;
        if (existingVerification.isPresent()) {
            // Update existing verification
            verification = existingVerification.get();
            verification.setVerificationStatus(status);
            verification.setFeedback(request.getFeedback());
            verification.setRejectionReason(request.getRejectionReason());
            verification.setLatitude(request.getLatitude());
            verification.setLongitude(request.getLongitude());
            if (status == FarmVerification.VerificationStatus.VERIFIED || 
                status == FarmVerification.VerificationStatus.REJECTED) {
                verification.setVerifiedAt(LocalDateTime.now());
            }
            log.info("Updating existing verification ID: {}", verification.getId());
        } else {
            // Create new verification
            verification = FarmVerification.builder()
                    .farmId(request.getFarmId())
                    .fieldOfficerId(fieldOfficer.getId())
                    .verificationStatus(status)
                    .feedback(request.getFeedback())
                    .rejectionReason(request.getRejectionReason())
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .verifiedAt((status == FarmVerification.VerificationStatus.VERIFIED || 
                                status == FarmVerification.VerificationStatus.REJECTED) 
                            ? LocalDateTime.now() 
                            : null)
                    .build();
            log.info("Creating new verification for farm ID: {}", request.getFarmId());
        }

        FarmVerification saved = verificationRepository.save(verification);

        // Save verification photos if provided
        if (request.getPhotoUrls() != null && !request.getPhotoUrls().isEmpty()) {
            // Delete existing photos for this verification (if updating)
            photoRepository.deleteByVerificationId(saved.getId());
            
            // Save new photos
            for (String photoUrl : request.getPhotoUrls()) {
                VerificationPhoto photo = VerificationPhoto.builder()
                        .verificationId(saved.getId())
                        .photoUrl(photoUrl)
                        .photoType(VerificationPhoto.PhotoType.FARM_OVERVIEW) // Default type
                        .description("Geotagged farm verification photo")
                        .build();
                photoRepository.save(photo);
                log.info("Saved verification photo URL: {} for verification ID: {}", 
                        photoUrl, saved.getId());
            }
        }
        log.info("Farm verification saved successfully - ID: {}, Farm: {}, Status: {}", 
                saved.getId(), request.getFarmId(), status);

        // Update assignment status if verification is completed
        if (status == FarmVerification.VerificationStatus.VERIFIED) {
            updateAssignmentStatusAfterVerification(assignmentOpt.get(), fieldOfficer.getId());
            // Update farm verification status in farmer-service
            updateFarmVerificationStatusInFarmerService(request.getFarmId(), true, fieldOfficer.getUserId(), request.getFeedback());
        } else if (status == FarmVerification.VerificationStatus.REJECTED) {
            // If rejected, mark as not verified in farmer-service
            updateFarmVerificationStatusInFarmerService(request.getFarmId(), false, null, request.getRejectionReason());
        }

        return VerifyFarmResponse.builder()
                .verificationId(saved.getId())
                .farmId(saved.getFarmId())
                .fieldOfficerId(saved.getFieldOfficerId())
                .status(saved.getVerificationStatus().name())
                .feedback(saved.getFeedback())
                .rejectionReason(saved.getRejectionReason())
                .latitude(saved.getLatitude())
                .longitude(saved.getLongitude())
                .verifiedAt(saved.getVerifiedAt())
                .createdAt(saved.getCreatedAt())
                .updatedAt(saved.getUpdatedAt())
                .build();
    }

    /**
     * Get verification for a specific farm by the logged-in field officer.
     */
    public Optional<VerifyFarmResponse> getVerification(Long farmId, Long fieldOfficerUserId) {
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Field officer not found with userId: " + fieldOfficerUserId));

        Optional<FarmVerification> verification = 
                verificationRepository.findByFarmIdAndFieldOfficerId(farmId, fieldOfficer.getId());

        return verification.map(v -> VerifyFarmResponse.builder()
                .verificationId(v.getId())
                .farmId(v.getFarmId())
                .fieldOfficerId(v.getFieldOfficerId())
                .status(v.getVerificationStatus().name())
                .feedback(v.getFeedback())
                .rejectionReason(v.getRejectionReason())
                .latitude(v.getLatitude())
                .longitude(v.getLongitude())
                .verifiedAt(v.getVerifiedAt())
                .createdAt(v.getCreatedAt())
                .updatedAt(v.getUpdatedAt())
                .build());
    }

    /**
     * Update assignment status after farm verification.
     * If all farms in the assignment are verified, mark assignment as COMPLETED.
     * Otherwise, mark as IN_PROGRESS if currently ASSIGNED.
     */
    private void updateAssignmentStatusAfterVerification(
            FieldOfficerAssignment assignment, Long fieldOfficerId) {
        try {
            log.info("Checking if assignment {} should be updated after verification", assignment.getId());

            boolean allFarmsVerified = false;

            if (assignment.getFarmId() != null) {
                // Assignment is for a specific farm
                // Check if this farm is verified
                Optional<FarmVerification> verification = verificationRepository
                        .findByFarmIdAndFieldOfficerId(assignment.getFarmId(), fieldOfficerId);
                
                if (verification.isPresent() && 
                    verification.get().getVerificationStatus() == FarmVerification.VerificationStatus.VERIFIED) {
                    allFarmsVerified = true;
                    log.info("Assignment {} is for specific farm {} which is now verified", 
                            assignment.getId(), assignment.getFarmId());
                }
            } else {
                // Assignment is for all farms of the farmer (farmId = NULL)
                // Check if all farms of the farmer are verified
                allFarmsVerified = areAllFarmerFarmsVerified(assignment.getFarmerUserId(), fieldOfficerId);
                log.info("Assignment {} is for all farms of farmer {}. All farms verified: {}", 
                        assignment.getId(), assignment.getFarmerUserId(), allFarmsVerified);
            }

            // Update assignment status
            FieldOfficerAssignment.AssignmentStatus newStatus;
            if (allFarmsVerified) {
                newStatus = FieldOfficerAssignment.AssignmentStatus.COMPLETED;
                assignment.setCompletedAt(LocalDateTime.now());
                log.info("Marking assignment {} as COMPLETED - all farms are verified", assignment.getId());
            } else {
                // If not all farms are verified, but at least one is, mark as IN_PROGRESS
                if (assignment.getStatus() == FieldOfficerAssignment.AssignmentStatus.ASSIGNED) {
                    newStatus = FieldOfficerAssignment.AssignmentStatus.IN_PROGRESS;
                    log.info("Marking assignment {} as IN_PROGRESS - some farms are verified", assignment.getId());
                } else {
                    // Keep current status if already IN_PROGRESS
                    log.info("Assignment {} already has status {}, keeping it", 
                            assignment.getId(), assignment.getStatus());
                    return;
                }
            }

            assignment.setStatus(newStatus);
            assignmentRepository.save(assignment);
            log.info("Assignment {} status updated to {}", assignment.getId(), newStatus);

        } catch (Exception e) {
            log.error("Error updating assignment status after verification for assignment {}: {}", 
                    assignment.getId(), e.getMessage(), e);
            // Don't throw - verification was successful, assignment status update is secondary
        }
    }

    /**
     * Check if all farms of a farmer are verified by the given field officer.
     */
    private boolean areAllFarmerFarmsVerified(Long farmerUserId, Long fieldOfficerId) {
        try {
            // Fetch all farms for the farmer
            List<Map<String, Object>> farms = fetchFarmerFarms(farmerUserId);
            
            if (farms.isEmpty()) {
                log.warn("No farms found for farmer userId: {}. Cannot determine if all farms are verified.", 
                        farmerUserId);
                return false;
            }

            log.info("Checking verification status for {} farms of farmer userId: {}", 
                    farms.size(), farmerUserId);

            // Check if all farms are verified
            for (Map<String, Object> farm : farms) {
                Object farmIdObj = farm.get("farmId");
                if (farmIdObj == null) {
                    farmIdObj = farm.get("id");
                }
                
                if (farmIdObj == null) {
                    log.warn("Farm entry missing farmId/id field: {}", farm);
                    continue;
                }

                Long farmId;
                if (farmIdObj instanceof Number) {
                    farmId = ((Number) farmIdObj).longValue();
                } else {
                    try {
                        farmId = Long.parseLong(farmIdObj.toString());
                    } catch (NumberFormatException e) {
                        log.warn("Cannot parse farmId: {}", farmIdObj);
                        continue;
                    }
                }

                // Check if this farm is verified
                Optional<FarmVerification> verification = verificationRepository
                        .findByFarmIdAndFieldOfficerId(farmId, fieldOfficerId);

                if (verification.isEmpty() || 
                    verification.get().getVerificationStatus() != FarmVerification.VerificationStatus.VERIFIED) {
                    log.info("Farm {} is not verified yet. Not all farms are verified.", farmId);
                    return false;
                }
            }

            log.info("All {} farms of farmer userId {} are verified", farms.size(), farmerUserId);
            return true;

        } catch (Exception e) {
            log.error("Error checking if all farms are verified for farmer userId {}: {}", 
                    farmerUserId, e.getMessage(), e);
            return false; // Conservative: assume not all farms are verified if we can't check
        }
    }

    /**
     * Fetch all farms for a farmer from farmer-service.
     * Similar to FieldOfficerAssignmentService.fetchFarmerFarms().
     */
    private List<Map<String, Object>> fetchFarmerFarms(Long farmerUserId) {
        try {
            log.info("Fetching farms for farmer userId: {}", farmerUserId);
            
            // Call admin endpoint to get farmer detail which includes farms
            String url = farmerServiceUrl + "/admin/farmers?page=0&size=1000";
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(url)
                    .header("X-User-Id", "1") // System admin user ID for inter-service calls
                    .header("X-User-Roles", "ADMIN") // Admin role for inter-service calls
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();

            if (response == null) {
                log.error("No response from farmer-service for userId: {}", farmerUserId);
                return Collections.emptyList();
            }

            // Unwrap ApiResponse
            Object dataObj = response.get("data");
            if (!(dataObj instanceof Map)) {
                log.error("Unexpected response structure from farmer-service for userId: {}", farmerUserId);
                return Collections.emptyList();
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) dataObj;
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmers = (List<Map<String, Object>>) data.get("farmers");

            if (farmers == null || farmers.isEmpty()) {
                log.warn("No farmers in response for userId: {}", farmerUserId);
                return Collections.emptyList();
            }

            // Find farmer with matching userId
            Optional<Map<String, Object>> farmerOpt = farmers.stream()
                    .filter(farmer -> {
                        Object userIdObj = farmer.get("userId");
                        if (userIdObj instanceof Number) {
                            return ((Number) userIdObj).longValue() == farmerUserId;
                        }
                        return String.valueOf(userIdObj).equals(String.valueOf(farmerUserId));
                    })
                    .findFirst();

            if (farmerOpt.isEmpty()) {
                log.warn("Farmer not found with userId: {}", farmerUserId);
                return Collections.emptyList();
            }

            Map<String, Object> farmer = farmerOpt.get();
            Object farmsObj = farmer.get("farms");

            if (farmsObj == null) {
                log.warn("No farms in farmer data for userId: {}", farmerUserId);
                return Collections.emptyList();
            }

            if (farmsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> farms = (List<Map<String, Object>>) farmsObj;
                log.info("Found {} farms for farmer userId: {}", farms.size(), farmerUserId);
                return farms;
            } else {
                log.warn("Farms data is not a list for userId: {}. Type: {}", 
                        farmerUserId, farmsObj.getClass().getName());
                return Collections.emptyList();
            }

        } catch (Exception e) {
            log.error("Error fetching farms for farmer userId {}: {}", farmerUserId, e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    /**
     * Update farm verification status in farmer-service.
     * This ensures the farms.is_verified field is updated when a field officer verifies a farm.
     */
    private void updateFarmVerificationStatusInFarmerService(
            Long farmId, boolean isVerified, Long verifiedByOfficerId, String remarks) {
        try {
            log.info("=== UPDATING FARM VERIFICATION STATUS IN FARMER-SERVICE ===");
            log.info("Farm ID: {}, isVerified: {}, verifiedByOfficerId: {}", 
                    farmId, isVerified, verifiedByOfficerId);
            
            String url = farmerServiceUrl + "/farmer/profile/farms/" + farmId + "/verification";
            log.info("Calling URL: {}", url);
            
            Map<String, Object> requestBody = new java.util.HashMap<>();
            requestBody.put("isVerified", isVerified);
            if (verifiedByOfficerId != null) {
                requestBody.put("verifiedByOfficerId", verifiedByOfficerId);
            }
            if (remarks != null && !remarks.trim().isEmpty()) {
                requestBody.put("verificationRemarks", remarks);
            }
            
            log.info("Request body: {}", requestBody);
            
            String response = webClientBuilder.build()
                    .put()
                    .uri(url)
                    .header("Content-Type", "application/json")
                    .header("X-User-Id", String.valueOf(verifiedByOfficerId != null ? verifiedByOfficerId : 1))
                    .header("X-User-Roles", "FIELD_OFFICER")
                    .body(BodyInserters.fromValue(requestBody))
                    .retrieve()
                    .onStatus(status -> status.isError(), clientResponse -> {
                        log.error("HTTP {} error from farmer-service verification endpoint", 
                                clientResponse.statusCode());
                        return clientResponse.bodyToMono(String.class)
                                .doOnNext(body -> log.error("Error response body: {}", body))
                                .map(body -> new RuntimeException("Farmer service error: " + 
                                        clientResponse.statusCode() + " - " + body));
                    })
                    .bodyToMono(String.class)
                    .doOnNext(resp -> log.info("Response from farmer-service: {}", resp))
                    .doOnError(error -> log.error("Error in WebClient call: {}", error.getMessage(), error))
                    .block();
            
            log.info("=== SUCCESSFULLY UPDATED FARM VERIFICATION STATUS IN FARMER-SERVICE ===");
            log.info("Farm ID: {}, Response: {}", farmId, response);
        } catch (Exception e) {
            log.error("=== ERROR UPDATING FARM VERIFICATION STATUS IN FARMER-SERVICE ===");
            log.error("Farm ID: {}, Error: {}", farmId, e.getMessage(), e);
            // Don't throw - verification was successful, this is just a sync operation
        }
    }
}

