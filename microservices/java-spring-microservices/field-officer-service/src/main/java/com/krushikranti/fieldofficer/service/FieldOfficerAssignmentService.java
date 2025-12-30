package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.AssignFieldOfficerRequest;
import com.krushikranti.fieldofficer.dto.AssignmentResponseDto;
import com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto;
import com.krushikranti.fieldofficer.dto.FieldOfficerSummaryDto;
import com.krushikranti.fieldofficer.dto.SuggestedFieldOfficerDto;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for field officer assignment operations.
 * Handles pincode-based matching and assignment management.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FieldOfficerAssignmentService {

    private final FieldOfficerRepository fieldOfficerRepository;
    private final FieldOfficerAssignmentRepository assignmentRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.farmer-service.url:http://localhost:4000}")
    private String farmerServiceUrl;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    /**
     * Get suggested field officers for a farmer based on pincode matching.
     * - If farms have pincodes: show ONLY field officers with matching pincodes
     * - If no matches found (but farms have pincodes): show all field officers
     * - If no farms or no pincodes: show all field officers for manual selection
     */
    public List<SuggestedFieldOfficerDto> getSuggestedFieldOfficers(Long farmerUserId) {
        log.info("Getting suggested field officers for farmer userId: {}", farmerUserId);
        
        // Step 1: Get all farms for the farmer
        List<Map<String, Object>> farms = fetchFarmerFarms(farmerUserId);
        List<FieldOfficer> fieldOfficersToReturn;
        boolean isManualSelection = false;
        
        // Step 2: Extract unique pincodes from farms (if farms exist)
        Set<String> farmPincodes = Collections.emptySet();
        if (farms != null && !farms.isEmpty()) {
            log.debug("Processing {} farms for pincode extraction", farms.size());
            farmPincodes = farms.stream()
                    .map(farm -> {
                        Object pincodeObj = farm.get("pincode");
                        if (pincodeObj == null) {
                            log.debug("Farm {} has null pincode", farm.get("farmName"));
                            return null;
                        }
                        // Handle both String and Number types
                        String pincode;
                        if (pincodeObj instanceof String) {
                            pincode = ((String) pincodeObj).trim();
                        } else if (pincodeObj instanceof Number) {
                            pincode = String.valueOf(pincodeObj).trim();
                        } else {
                            pincode = pincodeObj.toString().trim();
                        }
                        log.debug("Extracted pincode: {} from farm: {}", pincode, farm.get("farmName"));
                        return pincode.isEmpty() ? null : pincode;
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
            
            log.info("Extracted {} unique pincodes from farms: {}", farmPincodes.size(), farmPincodes);
        }
        
        // Step 3: Determine which field officers to return
        if (farmPincodes.isEmpty()) {
            // No farms or no pincodes - return all field officers for manual selection
            log.info("No farms or no pincodes found for farmer userId: {}. Returning all active field officers for manual selection.", farmerUserId);
            fieldOfficersToReturn = fieldOfficerRepository.findByIsActive(true, 
                    PageRequest.of(0, 1000)).getContent();
            isManualSelection = true;
        } else {
            // Farms have pincodes - try to find matching field officers first
            log.info("Searching for field officers with pincodes: {}", farmPincodes);
            
            // Step 4: Find field officers with matching pincodes
            List<String> pincodeList = new ArrayList<>(farmPincodes);
            fieldOfficersToReturn = fieldOfficerRepository.findByPincodeInAndIsActiveTrue(pincodeList);
            
            log.info("Found {} field officers with matching pincodes. Searched for: {}", 
                    fieldOfficersToReturn.size(), pincodeList);
            
            // Log the pincodes of found field officers for debugging
            if (!fieldOfficersToReturn.isEmpty()) {
                List<String> foundPincodes = fieldOfficersToReturn.stream()
                        .map(FieldOfficer::getPincode)
                        .collect(Collectors.toList());
                log.info("Found field officers with pincodes: {}", foundPincodes);
            }
            
            // If no matching field officers found, return all active ones for manual selection
            if (fieldOfficersToReturn.isEmpty()) {
                log.warn("No field officers found with matching pincodes {}. Returning all active field officers for manual selection.", pincodeList);
                // Verify: Let's check if there are any field officers with these pincodes at all (for debugging)
                List<FieldOfficer> allFieldOfficers = fieldOfficerRepository.findAll();
                Map<String, Long> pincodeCounts = allFieldOfficers.stream()
                        .filter(FieldOfficer::getIsActive)
                        .collect(Collectors.groupingBy(
                                fo -> fo.getPincode() != null ? fo.getPincode() : "NULL",
                                Collectors.counting()));
                log.warn("Available field officer pincodes and counts: {}", pincodeCounts);
                
                fieldOfficersToReturn = fieldOfficerRepository.findByIsActive(true, 
                        PageRequest.of(0, 1000)).getContent();
                isManualSelection = true;
            } else {
                // We have matching field officers - return ONLY those (not all)
                // CRITICAL: Do NOT return all field officers here - only return the matching ones
                log.info("SUCCESS: Found {} matching field officers. Returning ONLY these (not all field officers).", 
                        fieldOfficersToReturn.size());
                // isManualSelection remains false - we have matches
            }
        }
        
        if (fieldOfficersToReturn.isEmpty()) {
            log.warn("No active field officers found in the system");
            return Collections.emptyList();
        }
        
        // Final verification: Log what we're about to return
        if (!isManualSelection) {
            log.info("FINAL: Returning {} field officers with matching pincodes (NOT all field officers)", 
                    fieldOfficersToReturn.size());
        } else {
            log.info("FINAL: Returning {} field officers (all active - manual selection mode)", 
                    fieldOfficersToReturn.size());
        }
        
        // Step 4: Build suggested field officers with matching info
        List<Long> userIds = fieldOfficersToReturn.stream()
                .map(FieldOfficer::getUserId)
                .collect(Collectors.toList());
        
        Map<Long, Map<String, Object>> userMap = fetchUserDetailsBatch(userIds);
        
        // Create final copies for use in lambda
        final boolean finalIsManualSelection = isManualSelection;
        final List<Map<String, Object>> finalFarms = farms;
        
        return fieldOfficersToReturn.stream()
                .filter(fo -> {
                    if (fo.getId() == null || fo.getId() <= 0) {
                        log.error("Field officer has invalid ID: {}", fo);
                        return false;
                    }
                    return true;
                })
                .map(fo -> {
                    Map<String, Object> userDetails = userMap.getOrDefault(fo.getUserId(), new HashMap<>());
                    
                    // Find which farm pincodes match this field officer's pincode (if farms exist)
                    List<String> matchingPincodes = Collections.emptyList();
                    int matchingFarmCount = 0;
                    
                    if (!finalIsManualSelection && finalFarms != null && !finalFarms.isEmpty()) {
                        matchingPincodes = finalFarms.stream()
                                .map(farm -> (String) farm.get("pincode"))
                                .filter(pincode -> pincode != null && pincode.equals(fo.getPincode()))
                                .distinct()
                                .collect(Collectors.toList());
                        
                        matchingFarmCount = (int) finalFarms.stream()
                                .map(farm -> (String) farm.get("pincode"))
                                .filter(pincode -> pincode != null && pincode.equals(fo.getPincode()))
                                .count();
                    }
                    
                    return SuggestedFieldOfficerDto.builder()
                            .fieldOfficerId(fo.getId())
                            .userId(fo.getUserId())
                            .fullName(buildFullName(fo.getFirstName(), fo.getLastName()))
                            .username((String) userDetails.getOrDefault("username", ""))
                            .phoneNumber((String) userDetails.getOrDefault("phoneNumber", ""))
                            .email((String) userDetails.getOrDefault("email", ""))
                            .pincode(fo.getPincode())
                            .village(fo.getVillage())
                            .district(fo.getDistrict())
                            .state(fo.getState())
                            .isActive(fo.getIsActive())
                            .matchingPincodes(matchingPincodes)
                            .matchingFarmCount(matchingFarmCount)
                            .build();
                })
                .collect(Collectors.toList());
    }

    /**
     * Assign a field officer to a specific farm of a farmer.
     * Includes comprehensive validations:
     * - Field officer must be active
     * - Farm must exist and belong to the farmer
     * - Farm must be active
     * - Farm must not already be assigned to another field officer
     */
    @Transactional
    public AssignmentResponseDto assignFieldOfficerToFarmer(AssignFieldOfficerRequest request, Long adminUserId) {
        log.info("Assigning field officer {} to farm {} of farmer userId {} by admin {}", 
                request.getFieldOfficerId(), request.getFarmId(), request.getFarmerUserId(), adminUserId);
        
        // Validation 1: Validate required fields
        if (request.getFieldOfficerId() == null || request.getFieldOfficerId() <= 0) {
            log.error("Invalid field officer ID: {}", request.getFieldOfficerId());
            throw new IllegalArgumentException("Invalid field officer ID: " + request.getFieldOfficerId());
        }
        
        if (request.getFarmId() == null || request.getFarmId() <= 0) {
            log.error("Invalid farm ID: {}", request.getFarmId());
            throw new IllegalArgumentException("Invalid farm ID: " + request.getFarmId());
        }
        
        if (request.getFarmerUserId() == null || request.getFarmerUserId() <= 0) {
            log.error("Invalid farmer user ID: {}", request.getFarmerUserId());
            throw new IllegalArgumentException("Invalid farmer user ID: " + request.getFarmerUserId());
        }
        
        // Validation 2: Check if field officer exists and is active
        Optional<FieldOfficer> fieldOfficerOpt = fieldOfficerRepository.findById(request.getFieldOfficerId());
        
        if (fieldOfficerOpt.isEmpty()) {
            List<FieldOfficer> allFieldOfficers = fieldOfficerRepository.findAll();
            log.error("Field officer not found with ID: {}. Available field officer IDs: {}", 
                    request.getFieldOfficerId(),
                    allFieldOfficers.stream().map(FieldOfficer::getId).collect(Collectors.toList()));
            throw new IllegalArgumentException(
                    "Field officer not found with ID: " + request.getFieldOfficerId() + 
                    ". Please check the field officer ID and try again.");
        }
        
        FieldOfficer fieldOfficer = fieldOfficerOpt.get();
        
        if (!fieldOfficer.getIsActive()) {
            log.warn("Attempt to assign inactive field officer ID: {}", request.getFieldOfficerId());
            throw new IllegalArgumentException("Field officer is not active. Cannot assign inactive field officers.");
        }
        
        // Validation 3: Verify farm exists, belongs to farmer, and is active
        // Also validates KYC and subscription status
        Map<String, Object> farmDetails = validateAndGetFarmDetails(request.getFarmId(), request.getFarmerUserId());
        
        // Validation 4: Check KYC and Subscription status
        validateFarmerKycAndSubscription(request.getFarmerUserId());
        
        // Validation 5: Check if farm is already assigned to another field officer
        Optional<FieldOfficerAssignment> existingFarmAssignment = 
                assignmentRepository.findActiveAssignmentByFarmId(request.getFarmId());
        
        if (existingFarmAssignment.isPresent()) {
            FieldOfficerAssignment existing = existingFarmAssignment.get();
            
            // Get details of the assigned field officer
            Optional<FieldOfficer> assignedOfficerOpt = fieldOfficerRepository.findById(existing.getFieldOfficerId());
            String assignedOfficerName = "Unknown";
            if (assignedOfficerOpt.isPresent()) {
                FieldOfficer assignedOfficer = assignedOfficerOpt.get();
                assignedOfficerName = buildFullName(assignedOfficer.getFirstName(), assignedOfficer.getLastName());
            }
            
            String farmName = (String) farmDetails.getOrDefault("farmName", "Unknown Farm");
            String errorMessage = String.format(
                    "Farm '%s' (ID: %d) is already assigned to field officer '%s' (ID: %d). " +
                    "Assignment Status: %s, Assigned At: %s. " +
                    "Please cancel the existing assignment or select a different farm.",
                    farmName,
                    request.getFarmId(),
                    assignedOfficerName,
                    existing.getFieldOfficerId(),
                    existing.getStatus(),
                    existing.getAssignedAt()
            );
            
            log.warn("Assignment conflict: {}", errorMessage);
            throw new IllegalArgumentException(errorMessage);
        }
        
        // Validation 6: Check if same field officer is already assigned to this farm (duplicate check)
        Optional<FieldOfficerAssignment> duplicateAssignment = 
                assignmentRepository.findActiveAssignmentByFieldOfficerAndFarm(
                        request.getFieldOfficerId(), request.getFarmId());
        
        if (duplicateAssignment.isPresent()) {
            String farmName = (String) farmDetails.getOrDefault("farmName", "Unknown Farm");
            throw new IllegalArgumentException(
                    String.format("Field officer is already assigned to farm '%s' (ID: %d). " +
                            "Assignment ID: %d, Status: %s",
                            farmName, request.getFarmId(),
                            duplicateAssignment.get().getId(),
                            duplicateAssignment.get().getStatus()));
        }
        
        // All validations passed - Create new assignment
        FieldOfficerAssignment assignment = FieldOfficerAssignment.builder()
                .fieldOfficerId(request.getFieldOfficerId())
                .farmerUserId(request.getFarmerUserId())
                .farmId(request.getFarmId())
                .status(FieldOfficerAssignment.AssignmentStatus.ASSIGNED)
                .assignedByUserId(adminUserId)
                .notes(request.getNotes())
                .build();
        
        FieldOfficerAssignment saved = assignmentRepository.save(assignment);
        log.info("Assignment created successfully - ID: {}, Field Officer: {}, Farm: {}", 
                saved.getId(), request.getFieldOfficerId(), request.getFarmId());
        
        // Fetch field officer details for response
        Map<String, Object> userDetails = fetchUserDetails(fieldOfficer.getUserId());
        
        return AssignmentResponseDto.fromEntity(
                saved,
                buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                (String) userDetails.getOrDefault("phoneNumber", ""),
                fieldOfficer.getPincode()
        );
    }
    
    /**
     * Validate that farm exists, belongs to the farmer, and is active.
     * Returns farm details if valid, throws exception otherwise.
     */
    private Map<String, Object> validateAndGetFarmDetails(Long farmId, Long farmerUserId) {
        log.info("Validating farm ID: {} for farmer userId: {}", farmId, farmerUserId);
        
        try {
            // First, get farmer details to find farmerId
            Map<String, Object> farmerListResponse = webClientBuilder.build()
                    .get()
                    .uri(farmerServiceUrl + "/admin/farmers?page=0&size=1000")
                    .header("X-User-Id", "1")
                    .header("X-User-Roles", "ADMIN")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (farmerListResponse == null) {
                throw new IllegalArgumentException("Failed to fetch farmer information");
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) farmerListResponse.get("data");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmers = (List<Map<String, Object>>) data.get("farmers");
            
            Optional<Map<String, Object>> farmerOpt = farmers.stream()
                    .filter(f -> {
                        Object userIdObj = f.get("userId");
                        if (userIdObj instanceof Number) {
                            return ((Number) userIdObj).longValue() == farmerUserId;
                        }
                        return String.valueOf(userIdObj).equals(String.valueOf(farmerUserId));
                    })
                    .findFirst();
            
            if (farmerOpt.isEmpty()) {
                throw new IllegalArgumentException("Farmer not found with userId: " + farmerUserId);
            }
            
            Long farmerId = ((Number) farmerOpt.get().get("farmerId")).longValue();
            
            // Get farmer detail with farms
            Map<String, Object> farmerDetailResponse = webClientBuilder.build()
                    .get()
                    .uri(farmerServiceUrl + "/admin/farmers/" + farmerId)
                    .header("X-User-Id", "1")
                    .header("X-User-Roles", "ADMIN")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (farmerDetailResponse == null) {
                throw new IllegalArgumentException("Failed to fetch farmer details");
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> detailData = (Map<String, Object>) ((Map<String, Object>) farmerDetailResponse.get("data"));
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farms = (List<Map<String, Object>>) detailData.get("farms");
            
            if (farms == null || farms.isEmpty()) {
                throw new IllegalArgumentException("Farmer has no farms. Cannot assign field officer.");
            }
            
            // Find the specific farm
            Optional<Map<String, Object>> farmOpt = farms.stream()
                    .filter(farm -> {
                        Object farmIdObj = farm.get("farmId");
                        if (farmIdObj == null) {
                            farmIdObj = farm.get("id");
                        }
                        if (farmIdObj instanceof Number) {
                            return ((Number) farmIdObj).longValue() == farmId;
                        }
                        return String.valueOf(farmIdObj).equals(String.valueOf(farmId));
                    })
                    .findFirst();
            
            if (farmOpt.isEmpty()) {
                String farmNames = farms.stream()
                        .map(f -> String.valueOf(f.getOrDefault("farmName", "Unknown")))
                        .collect(Collectors.joining(", "));
                throw new IllegalArgumentException(
                        String.format("Farm ID %d does not belong to farmer userId %d. " +
                                "Available farms: %s",
                                farmId, farmerUserId, farmNames));
            }
            
            Map<String, Object> farm = farmOpt.get();
            
            // Check if farm is active (assuming there's an isActive field)
            Object isActiveObj = farm.get("isActive");
            if (isActiveObj != null && isActiveObj instanceof Boolean && !((Boolean) isActiveObj)) {
                String farmName = (String) farm.getOrDefault("farmName", "Unknown Farm");
                throw new IllegalArgumentException(
                        String.format("Farm '%s' (ID: %d) is not active. Cannot assign field officer to inactive farms.",
                                farmName, farmId));
            }
            
            log.info("Farm validation successful - Farm ID: {}, Farm Name: {}", 
                    farmId, farm.getOrDefault("farmName", "Unknown"));
            return farm;
            
        } catch (IllegalArgumentException e) {
            throw e; // Re-throw validation exceptions
        } catch (Exception e) {
            log.error("Error validating farm details: {}", e.getMessage(), e);
            throw new IllegalArgumentException(
                    "Failed to validate farm details: " + e.getMessage());
        }
    }
    
    /**
     * Validate that farmer's KYC and subscription are verified/active.
     * Throws exception if validation fails.
     */
    private void validateFarmerKycAndSubscription(Long farmerUserId) {
        log.info("Validating KYC and subscription for farmer userId: {}", farmerUserId);
        
        try {
            // Get farmer list to find farmerId
            Map<String, Object> farmerListResponse = webClientBuilder.build()
                    .get()
                    .uri(farmerServiceUrl + "/admin/farmers?page=0&size=1000")
                    .header("X-User-Id", "1")
                    .header("X-User-Roles", "ADMIN")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (farmerListResponse == null) {
                throw new IllegalArgumentException("Failed to fetch farmer information for KYC/subscription validation");
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) farmerListResponse.get("data");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmers = (List<Map<String, Object>>) data.get("farmers");
            
            Optional<Map<String, Object>> farmerOpt = farmers.stream()
                    .filter(f -> {
                        Object userIdObj = f.get("userId");
                        if (userIdObj instanceof Number) {
                            return ((Number) userIdObj).longValue() == farmerUserId;
                        }
                        return String.valueOf(userIdObj).equals(String.valueOf(farmerUserId));
                    })
                    .findFirst();
            
            if (farmerOpt.isEmpty()) {
                throw new IllegalArgumentException("Farmer not found with userId: " + farmerUserId);
            }
            
            Long farmerId = ((Number) farmerOpt.get().get("farmerId")).longValue();
            
            // Get farmer detail with KYC and subscription info
            Map<String, Object> farmerDetailResponse = webClientBuilder.build()
                    .get()
                    .uri(farmerServiceUrl + "/admin/farmers/" + farmerId)
                    .header("X-User-Id", "1")
                    .header("X-User-Roles", "ADMIN")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (farmerDetailResponse == null) {
                throw new IllegalArgumentException("Failed to fetch farmer details for KYC/subscription validation");
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> detailData = (Map<String, Object>) ((Map<String, Object>) farmerDetailResponse.get("data"));
            
            // Extract KYC info
            @SuppressWarnings("unchecked")
            Map<String, Object> kycInfo = (Map<String, Object>) detailData.get("kyc");
            if (kycInfo == null) {
                throw new IllegalArgumentException(
                        "KYC information not found for farmer. Please complete KYC verification before assigning a field officer.");
            }
            
            String kycStatus = (String) kycInfo.get("status");
            if (kycStatus == null || !kycStatus.equals("VERIFIED")) {
                throw new IllegalArgumentException(
                        String.format("Farmer's KYC is not verified. Current KYC Status: %s. " +
                                "Please verify the farmer's KYC before assigning a field officer.",
                                kycStatus != null ? kycStatus : "UNKNOWN"));
            }
            
            // Extract Subscription info
            @SuppressWarnings("unchecked")
            Map<String, Object> subscriptionInfo = (Map<String, Object>) detailData.get("subscription");
            if (subscriptionInfo == null) {
                throw new IllegalArgumentException(
                        "Subscription information not found for farmer. Please activate subscription before assigning a field officer.");
            }
            
            String subscriptionStatus = (String) subscriptionInfo.get("status");
            if (subscriptionStatus == null || !subscriptionStatus.equals("ACTIVE")) {
                throw new IllegalArgumentException(
                        String.format("Farmer's subscription is not active. Current Subscription Status: %s. " +
                                "Please activate the farmer's subscription before assigning a field officer.",
                                subscriptionStatus != null ? subscriptionStatus : "UNKNOWN"));
            }
            
            log.info("KYC and subscription validation successful - KYC: {}, Subscription: {}", 
                    kycStatus, subscriptionStatus);
            
        } catch (IllegalArgumentException e) {
            throw e; // Re-throw validation exceptions
        } catch (Exception e) {
            log.error("Error validating KYC and subscription: {}", e.getMessage(), e);
            throw new IllegalArgumentException(
                    "Failed to validate farmer's KYC and subscription: " + e.getMessage());
        }
    }

    /**
     * Get all assignments for a farmer.
     */
    public List<AssignmentResponseDto> getAssignmentsForFarmer(Long farmerUserId) {
        log.info("Getting assignments for farmer userId: {}", farmerUserId);
        
        List<FieldOfficerAssignment> assignments = assignmentRepository.findByFarmerUserId(farmerUserId);
        
        return assignments.stream()
                .map(assignment -> {
                    FieldOfficer fieldOfficer = fieldOfficerRepository.findById(assignment.getFieldOfficerId())
                            .orElse(null);
                    
                    if (fieldOfficer == null) {
                        log.warn("Field officer not found for assignment ID: {}", assignment.getId());
                        return AssignmentResponseDto.fromEntity(assignment, "Unknown", "", "");
                    }
                    
                    Map<String, Object> userDetails = fetchUserDetails(fieldOfficer.getUserId());
                    
                    return AssignmentResponseDto.fromEntity(
                            assignment,
                            buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                            (String) userDetails.getOrDefault("phoneNumber", ""),
                            fieldOfficer.getPincode()
                    );
                })
                .collect(Collectors.toList());
    }

    /**
     * Get all assignments for a field officer.
     */
    public Page<AssignmentResponseDto> getAssignmentsForFieldOfficer(Long fieldOfficerId, Pageable pageable) {
        log.info("Getting assignments for field officer ID: {}", fieldOfficerId);
        
        Page<FieldOfficerAssignment> assignments = assignmentRepository.findByFieldOfficerId(fieldOfficerId, pageable);
        
        return assignments.map(assignment -> {
            // For field officer view, we might want to fetch farmer details too
            // For now, just return basic assignment info
            FieldOfficer fieldOfficer = fieldOfficerRepository.findById(assignment.getFieldOfficerId())
                    .orElse(null);
            
            if (fieldOfficer == null) {
                return AssignmentResponseDto.fromEntity(assignment, "Unknown", "", "");
            }
            
            Map<String, Object> userDetails = fetchUserDetails(fieldOfficer.getUserId());
            
            return AssignmentResponseDto.fromEntity(
                    assignment,
                    buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                    (String) userDetails.getOrDefault("phoneNumber", ""),
                    fieldOfficer.getPincode()
            );
        });
    }

    /**
     * Get assignments with farm details for a field officer (by userId).
     * Used by field officer app to see their assigned farms.
     */
    public List<com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto> getAssignmentsWithFarmsForFieldOfficer(Long fieldOfficerUserId) {
        log.info("Getting assignments with farms for field officer userId: {}", fieldOfficerUserId);
        
        // Find field officer by userId
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException("Field officer not found with userId: " + fieldOfficerUserId));
        
        // Get all assignments for this field officer
        // Use PageRequest to get all assignments (no pagination needed for field officer view)
        Page<FieldOfficerAssignment> assignmentPage = assignmentRepository.findByFieldOfficerId(
                fieldOfficer.getId(), 
                PageRequest.of(0, 1000)); // Get up to 1000 assignments
        List<FieldOfficerAssignment> assignments = assignmentPage.getContent();
        
        log.info("Found {} assignments for field officer userId: {}", assignments.size(), fieldOfficerUserId);
        
        List<FieldOfficerAssignmentDto> result = assignments.stream()
                .map(assignment -> {
                    try {
                        // Fetch farmer details
                        Map<String, Object> farmerUserDetails = fetchUserDetails(assignment.getFarmerUserId());
                        String farmerNameTemp = buildFullName(
                                (String) farmerUserDetails.getOrDefault("firstName", ""),
                                (String) farmerUserDetails.getOrDefault("lastName", ""));
                        if (farmerNameTemp.trim().isEmpty()) {
                            farmerNameTemp = (String) farmerUserDetails.getOrDefault("username", "Unknown Farmer");
                        }
                        final String farmerName = farmerNameTemp; // Make final for lambda
                        String farmerPhone = (String) farmerUserDetails.getOrDefault("phoneNumber", "");
                        
                        // Fetch farms for this farmer
                        List<Map<String, Object>> farms;
                        try {
                            log.info("About to fetch farms for farmer userId: {} (assignment {})", 
                                    assignment.getFarmerUserId(), assignment.getId());
                            farms = fetchFarmerFarms(assignment.getFarmerUserId());
                            log.info("Fetched {} farms for farmer userId: {} (assignment {})", 
                                    farms.size(), assignment.getFarmerUserId(), assignment.getId());
                            
                            if (farms.isEmpty()) {
                                log.warn("WARNING: No farms returned for farmer userId: {} (assignment {}). " +
                                        "This could mean: 1) Farmer has no farms in database, 2) API call failed silently, " +
                                        "3) Response structure mismatch. Check detailed logs above.", 
                                        assignment.getFarmerUserId(), assignment.getId());
                            } else {
                                log.info("SUCCESS: Found {} farms for farmer userId: {}", 
                                        farms.size(), assignment.getFarmerUserId());
                            }
                        } catch (Exception e) {
                            log.error("EXCEPTION: Error fetching farms for farmer userId {} (assignment {}): {}", 
                                    assignment.getFarmerUserId(), assignment.getId(), e.getMessage(), e);
                            farms = Collections.emptyList(); // Return empty list if farms can't be fetched
                        }
                        
                        // Build location string for each farm and add assignment info
                        List<Map<String, Object>> farmsWithLocation = farms.stream()
                                .map(farm -> {
                                    try {
                                        Map<String, Object> farmWithLocation = new java.util.HashMap<>(farm);
                                        String location = String.format("%s, %s, %s - %s",
                                                farm.getOrDefault("village", ""),
                                                farm.getOrDefault("district", ""),
                                                farm.getOrDefault("state", ""),
                                                farm.getOrDefault("pincode", ""));
                                        farmWithLocation.put("location", location.trim());
                                        farmWithLocation.put("farmerName", farmerName);
                                        // Add assignment status (default to PENDING for verification)
                                        farmWithLocation.put("status", "PENDING");
                                        // Add assignment ID for reference
                                        farmWithLocation.put("assignmentId", assignment.getId());
                                        // Ensure farmName field exists (handle both farmName and farm_name)
                                        if (!farmWithLocation.containsKey("farmName") && farmWithLocation.containsKey("farm_name")) {
                                            farmWithLocation.put("farmName", farmWithLocation.get("farm_name"));
                                        }
                                        // Also handle id vs farmId
                                        if (!farmWithLocation.containsKey("farmId") && farmWithLocation.containsKey("id")) {
                                            farmWithLocation.put("farmId", farmWithLocation.get("id"));
                                        }
                                        return farmWithLocation;
                                    } catch (Exception e) {
                                        log.error("Error processing farm data: {}", e.getMessage(), e);
                                        return null;
                                    }
                                })
                                .filter(Objects::nonNull)
                                .collect(Collectors.toList());
                        
                        FieldOfficerAssignmentDto dto = FieldOfficerAssignmentDto.builder()
                                .assignmentId(assignment.getId())
                                .farmerUserId(assignment.getFarmerUserId())
                                .status(assignment.getStatus().name())
                                .notes(assignment.getNotes())
                                .assignedAt(assignment.getAssignedAt())
                                .assignedByUserId(assignment.getAssignedByUserId())
                                .farmerName(farmerName)
                                .farmerPhoneNumber(farmerPhone)
                                .farms(farmsWithLocation)
                                .build();
                        
                        log.debug("Created assignment DTO with {} farms for assignment {}", 
                                farmsWithLocation.size(), assignment.getId());
                        return dto;
                    } catch (Exception e) {
                        log.error("Error processing assignment {}: {}", assignment.getId(), e.getMessage(), e);
                        // Return a minimal assignment DTO even if there's an error
                        return FieldOfficerAssignmentDto.builder()
                                .assignmentId(assignment.getId())
                                .farmerUserId(assignment.getFarmerUserId())
                                .status(assignment.getStatus().name())
                                .notes(assignment.getNotes())
                                .assignedAt(assignment.getAssignedAt())
                                .assignedByUserId(assignment.getAssignedByUserId())
                                .farmerName("Unknown")
                                .farmerPhoneNumber("")
                                .farms(Collections.emptyList())
                                .build();
                    }
                })
                .collect(Collectors.toList());
        
        log.info("Returning {} assignments with total farms: {}", 
                result.size(), 
                result.stream().mapToInt(dto -> dto.getFarms() != null ? dto.getFarms().size() : 0).sum());
        return result;
    }

    // ==================== Helper Methods ====================

    /**
     * Fetch all farms for a farmer from farmer-service.
     * Uses the admin endpoint to get farmer detail which includes farms.
     */
    private List<Map<String, Object>> fetchFarmerFarms(Long farmerUserId) {
        try {
            log.info("=== Starting to fetch farms for farmer userId: {} ===", farmerUserId);
            log.info("Using farmer-service URL: {}", farmerServiceUrl);
            
            // Call admin endpoint to get farmer list and find the one with matching userId
            Map<String, Object> response;
            try {
                String url = farmerServiceUrl + "/admin/farmers?page=0&size=1000";
                log.info("Calling farmer-service list endpoint: {}", url);
                response = webClientBuilder.build()
                        .get()
                        .uri(url)
                        .header("X-User-Id", "1") // System admin user ID for inter-service calls
                        .header("X-User-Roles", "ADMIN") // Admin role for inter-service calls
                        .retrieve()
                        .onStatus(status -> status.isError(), clientResponse -> {
                            log.error("ERROR: HTTP {} from farmer-service list endpoint for userId: {}", 
                                    clientResponse.statusCode(), farmerUserId);
                            return clientResponse.bodyToMono(String.class)
                                    .doOnNext(body -> log.error("Error response body from list endpoint: {}", body))
                                    .map(body -> new RuntimeException("Farmer service error: " + 
                                            clientResponse.statusCode() + " - " + body));
                        })
                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                        .doOnNext(resp -> log.info("Successfully received response from farmer-service list endpoint"))
                        .doOnError(error -> log.error("Error in WebClient call to farmer-service list: {}", error.getMessage(), error))
                        .block();
                log.info("Response received from farmer-service list endpoint, response is null: {}", response == null);
            } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
                log.error("WebClientResponseException fetching farmers list for userId {}: Status: {}, Body: {}", 
                        farmerUserId, e.getStatusCode(), e.getResponseBodyAsString(), e);
                log.error("Full exception stack trace: ", e);
                return Collections.emptyList();
            } catch (Exception e) {
                log.error("Unexpected error calling farmer-service for userId {}: {}", farmerUserId, e.getMessage(), e);
                log.error("Full exception stack trace: ", e);
                return Collections.emptyList();
            }
            
            if (response == null) {
                log.error("ERROR: No response from farmer-service for userId: {}", farmerUserId);
                return Collections.emptyList();
            }
            
            log.info("Received response from farmer-service list endpoint. Response keys: {}", response.keySet());
            
            // Unwrap ApiResponse
            Object dataObj = response.get("data");
            if (!(dataObj instanceof Map)) {
                log.error("Unexpected response structure from farmer-service. Response type: {}, Response: {}", 
                        dataObj != null ? dataObj.getClass().getName() : "null", response);
                return Collections.emptyList();
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) dataObj;
            log.info("Data object keys: {}", data.keySet());
            
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmers = (List<Map<String, Object>>) data.get("farmers");
            
            if (farmers == null || farmers.isEmpty()) {
                log.error("No farmers in response for userId: {}. Data keys: {}", farmerUserId, data.keySet());
                return Collections.emptyList();
            }
            
            log.info("Found {} farmers in list response", farmers.size());
            
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
            Object farmerIdObj = farmer.get("farmerId");
            if (farmerIdObj == null) {
                log.warn("Farmer ID not found in farmer data for userId: {}", farmerUserId);
                return Collections.emptyList();
            }
            
            Long farmerId = ((Number) farmerIdObj).longValue();
            log.info("Found farmerId {} for userId {}", farmerId, farmerUserId);
            
            // Now get farmer detail with farms
            String detailUrl = farmerServiceUrl + "/admin/farmers/" + farmerId;
            log.info("Calling farmer detail endpoint: {}", detailUrl);
            Map<String, Object> detailResponse;
            try {
                detailResponse = webClientBuilder.build()
                        .get()
                        .uri(detailUrl)
                        .header("X-User-Id", "1") // System admin user ID for inter-service calls
                        .header("X-User-Roles", "ADMIN") // Admin role for inter-service calls
                        .retrieve()
                        .onStatus(status -> status.isError(), clientResponse -> {
                            log.error("ERROR: HTTP {} from farmer-service detail endpoint for farmerId: {}", 
                                    clientResponse.statusCode(), farmerId);
                            return clientResponse.bodyToMono(String.class)
                                    .doOnNext(body -> log.error("Error response body: {}", body))
                                    .map(body -> new RuntimeException("Farmer service error: " + 
                                            clientResponse.statusCode() + " - " + body));
                        })
                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                        .doOnNext(detailResp -> log.info("Successfully received response from farmer-service detail endpoint"))
                        .doOnError(error -> log.error("Error in WebClient call to farmer-service detail: {}", error.getMessage(), error))
                        .block();
            } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
                log.error("WebClientResponseException fetching farmer detail for farmerId {}: Status: {}, Body: {}", 
                        farmerId, e.getStatusCode(), e.getResponseBodyAsString(), e);
                log.error("Full exception details: ", e);
                // Don't throw - return empty list instead
                return Collections.emptyList();
            } catch (Exception e) {
                log.error("Unexpected error calling farmer-service detail for farmerId {}: {}", farmerId, e.getMessage(), e);
                // Don't throw - return empty list instead
                return Collections.emptyList();
            }
            
            if (detailResponse == null) {
                log.error("No detail response from farmer-service for farmerId: {}", farmerId);
                return Collections.emptyList();
            }
            
            log.info("Received detail response. Response keys: {}", detailResponse.keySet());
            
            // Unwrap ApiResponse
            Object detailDataObj = detailResponse.get("data");
            if (!(detailDataObj instanceof Map)) {
                log.error("Unexpected detail response structure. Data type: {}, Response: {}", 
                        detailDataObj != null ? detailDataObj.getClass().getName() : "null", detailResponse);
                return Collections.emptyList();
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> detailData = (Map<String, Object>) detailDataObj;
            log.info("Detail data keys: {}", detailData.keySet());
            log.info("Full detail data structure: {}", detailData);
            
            // Extract farms from the response - AdminFarmerDetailDto has farms as a list of FarmInfo objects
            Object farmsObj = detailData.get("farms");
            
            if (farmsObj == null) {
                log.error("ERROR: Farms key is null in detail data for farmer userId: {}. Available keys: {}", 
                        farmerUserId, detailData.keySet());
                log.error("Full detail data: {}", detailData);
                return Collections.emptyList();
            }
            
            log.info("Farms object type: {}, value: {}", farmsObj.getClass().getName(), farmsObj);
            
            if (!(farmsObj instanceof List)) {
                log.error("ERROR: Farms is not a List for farmer userId: {}. Type: {}, Value: {}", 
                        farmerUserId, farmsObj.getClass().getName(), farmsObj);
                return Collections.emptyList();
            }
            
            // Convert farms list to proper format - handle different response types
            @SuppressWarnings("unchecked")
            List<Object> farmsList = (List<Object>) farmsObj;
            
            log.info("Farms list size: {} for farmer userId: {}", farmsList.size(), farmerUserId);
            
            if (farmsList.isEmpty()) {
                log.warn("WARNING: Farms array is empty for farmer userId: {}. " +
                        "This means the farmer has NO farms in the database. " +
                        "To verify, check the database: SELECT * FROM farms WHERE farmer_id = " +
                        "(SELECT id FROM farmers WHERE user_id = {});", 
                        farmerUserId, farmerUserId);
                return Collections.emptyList();
            }
            
            // Convert each farm object to Map<String, Object>
            List<Map<String, Object>> farmMaps = new java.util.ArrayList<>();
            for (Object farmObj : farmsList) {
                try {
                    Map<String, Object> farmMap;
                    if (farmObj instanceof Map) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> tempMap = (Map<String, Object>) farmObj;
                        farmMap = new java.util.HashMap<>(tempMap);
                    } else {
                        log.warn("Farm object is not a Map, type: {}, value: {}", 
                                farmObj != null ? farmObj.getClass().getName() : "null", farmObj);
                        continue; // Skip this farm
                    }
                    
                    // Ensure farmName is present (handle both farmName and farm_name)
                    if (!farmMap.containsKey("farmName") && farmMap.containsKey("farm_name")) {
                        farmMap.put("farmName", farmMap.get("farm_name"));
                    }
                    // Ensure farmId is present (handle both farmId and id)
                    if (!farmMap.containsKey("farmId")) {
                        if (farmMap.containsKey("id")) {
                            farmMap.put("farmId", farmMap.get("id"));
                        } else if (farmMap.containsKey("farm_id")) {
                            farmMap.put("farmId", farmMap.get("farm_id"));
                        }
                    }
                    
                    farmMaps.add(farmMap);
                    log.debug("Converted farm: farmId={}, farmName={}, pincode={}", 
                            farmMap.get("farmId"), farmMap.get("farmName"), farmMap.get("pincode"));
                } catch (Exception e) {
                    log.error("Error converting farm object to Map: {}", e.getMessage(), e);
                    // Continue with next farm
                }
            }
            
            log.info("=== SUCCESS: Converted {} farms for farmer userId: {} ===", farmMaps.size(), farmerUserId);
            // Log first farm details for verification
            if (!farmMaps.isEmpty()) {
                Map<String, Object> firstFarm = farmMaps.get(0);
                log.info("Sample farm data - farmId: {}, farmName: {}, pincode: {}, all keys: {}", 
                        firstFarm.get("farmId"), firstFarm.get("farmName"), firstFarm.get("pincode"), 
                        firstFarm.keySet());
            }
            
            log.info("Converted {} farms to map format for farmer userId: {}", farmMaps.size(), farmerUserId);
            return farmMaps;
            
        } catch (Exception e) {
            // Log error but return empty list to avoid breaking the suggestions endpoint
            log.error("EXCEPTION in fetchFarmerFarms for farmer userId {}: {}", farmerUserId, e.getMessage(), e);
            log.error("Exception type: {}, Cause: {}", e.getClass().getName(), e.getCause());
            if (e.getStackTrace() != null && e.getStackTrace().length > 0) {
                log.error("Exception at: {}", e.getStackTrace()[0]);
            }
            return Collections.emptyList();
        }
    }

    private Map<String, Object> fetchUserDetails(Long userId) {
        try {
            return webClientBuilder.build()
                    .get()
                    .uri(authServiceUrl + "/auth/user/{userId}", userId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
        } catch (Exception e) {
            log.warn("Failed to fetch user details for userId {}: {}", userId, e.getMessage());
            return new HashMap<>();
        }
    }

    private Map<Long, Map<String, Object>> fetchUserDetailsBatch(List<Long> userIds) {
        Map<Long, Map<String, Object>> userMap = new HashMap<>();
        
        for (Long userId : userIds) {
            try {
                Map<String, Object> userDetails = fetchUserDetails(userId);
                userMap.put(userId, userDetails);
            } catch (Exception e) {
                log.warn("Failed to fetch user details for userId {}: {}", userId, e.getMessage());
            }
        }
        
        return userMap;
    }

    private String buildFullName(String firstName, String lastName) {
        String fn = firstName != null ? firstName : "";
        String ln = lastName != null ? lastName : "";
        return (fn + " " + ln).trim();
    }
}

