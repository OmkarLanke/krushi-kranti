package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.AssignFieldOfficerRequest;
import com.krushikranti.fieldofficer.dto.AssignmentResponseDto;
import com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto;
import com.krushikranti.fieldofficer.dto.SuggestedFieldOfficerDto;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.model.FarmVerification;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import com.krushikranti.fieldofficer.repository.FarmVerificationRepository;
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
    private final FarmVerificationRepository verificationRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.farmer-service.url:http://localhost:4000}")
    private String farmerServiceUrl;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    /**
     * Get suggested field officers for a farmer based on pincode matching.
     * - If farmId is provided: show ONLY field officers matching that specific farm's pincode
     * - If farmId is null but farms have pincodes: show field officers matching any farm's pincode
     * - If no matches found (but farms have pincodes): show all field officers
     * - If no farms or no pincodes: show all field officers for manual selection
     * 
     * @param farmerUserId The farmer's user ID
     * @param farmId Optional farm ID to filter by specific farm's pincode
     * @return List of suggested field officers with assignment info
     */
    public List<SuggestedFieldOfficerDto> getSuggestedFieldOfficers(Long farmerUserId, Long farmId) {
        log.info("Getting suggested field officers for farmer userId: {}, farmId: {}", farmerUserId, farmId);
        
        // Step 1: Get all farms for the farmer
        List<Map<String, Object>> farms = fetchFarmerFarms(farmerUserId);
        List<FieldOfficer> fieldOfficersToReturn;
        boolean isManualSelection = false;
        
        // Step 2: Extract pincodes based on farmId parameter
        Set<String> farmPincodes = Collections.emptySet();
        Map<String, Object> selectedFarm = null;
        
        if (farmId != null && farmId > 0) {
            // If farmId is provided, filter by that specific farm's pincode only
            if (farms != null && !farms.isEmpty()) {
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
                
                if (farmOpt.isPresent()) {
                    selectedFarm = farmOpt.get();
                    Object pincodeObj = selectedFarm.get("pincode");
                    if (pincodeObj != null) {
                        String pincode;
                        if (pincodeObj instanceof String) {
                            pincode = ((String) pincodeObj).trim();
                        } else if (pincodeObj instanceof Number) {
                            pincode = String.valueOf(pincodeObj).trim();
                        } else {
                            pincode = pincodeObj.toString().trim();
                        }
                        if (!pincode.isEmpty()) {
                            farmPincodes = Collections.singleton(pincode);
                            log.info("Filtering by specific farm ID {} with pincode: {}", farmId, pincode);
                        } else {
                            log.warn("Selected farm ID {} has empty pincode", farmId);
                        }
                    } else {
                        log.warn("Selected farm ID {} has null pincode", farmId);
                    }
                } else {
                    log.warn("Farm ID {} not found for farmer userId {}", farmId, farmerUserId);
                }
            }
        } else {
            // If no farmId provided, extract pincodes from all farms (original behavior)
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
                
                log.info("Extracted {} unique pincodes from all farms: {}", farmPincodes.size(), farmPincodes);
            }
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
        Map<Long, Integer> assignedFarmCounts = getAssignedFarmCounts(fieldOfficersToReturn.stream()
            .map(FieldOfficer::getId)
            .filter(Objects::nonNull)
            .collect(Collectors.toList()));
        
        // Create final copies for use in lambda
        final boolean finalIsManualSelection = isManualSelection;
        final List<Map<String, Object>> finalFarms = farms;
        final Map<String, Object> finalSelectedFarm = selectedFarm;
        
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
                    
                    // Find which farm pincodes match this field officer's pincode
                    List<String> matchingPincodes = Collections.emptyList();
                    int matchingFarmCount = 0;
                    
                    if (!finalIsManualSelection) {
                        if (finalSelectedFarm != null) {
                            // If a specific farm is selected, check if it matches
                            Object pincodeObj = finalSelectedFarm.get("pincode");
                            String farmPincode = null;
                            if (pincodeObj instanceof String) {
                                farmPincode = ((String) pincodeObj).trim();
                            } else if (pincodeObj instanceof Number) {
                                farmPincode = String.valueOf(pincodeObj).trim();
                            } else if (pincodeObj != null) {
                                farmPincode = pincodeObj.toString().trim();
                            }
                            
                            if (farmPincode != null && !farmPincode.isEmpty() && farmPincode.equals(fo.getPincode())) {
                                matchingPincodes = Collections.singletonList(farmPincode);
                                matchingFarmCount = 1;
                            }
                        } else if (finalFarms != null && !finalFarms.isEmpty()) {
                            // Original behavior: check all farms
                            matchingPincodes = finalFarms.stream()
                                    .map(farm -> {
                                        Object pincodeObj = farm.get("pincode");
                                        if (pincodeObj instanceof String) {
                                            return ((String) pincodeObj).trim();
                                        } else if (pincodeObj instanceof Number) {
                                            return String.valueOf(pincodeObj).trim();
                                        } else if (pincodeObj != null) {
                                            return pincodeObj.toString().trim();
                                        }
                                        return null;
                                    })
                                    .filter(pincode -> pincode != null && !pincode.isEmpty() && pincode.equals(fo.getPincode()))
                                    .distinct()
                                    .collect(Collectors.toList());
                            
                            matchingFarmCount = (int) finalFarms.stream()
                                    .map(farm -> {
                                        Object pincodeObj = farm.get("pincode");
                                        if (pincodeObj instanceof String) {
                                            return ((String) pincodeObj).trim();
                                        } else if (pincodeObj instanceof Number) {
                                            return String.valueOf(pincodeObj).trim();
                                        } else if (pincodeObj != null) {
                                            return pincodeObj.toString().trim();
                                        }
                                        return null;
                                    })
                                    .filter(pincode -> pincode != null && !pincode.isEmpty() && pincode.equals(fo.getPincode()))
                                    .count();
                        }
                    }
                    
                    Integer assignedFarmsCount = assignedFarmCounts.getOrDefault(fo.getId(), 0);
                    
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
                            .assignedFarmsCount(assignedFarmsCount)
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

        invalidateAdminFarmerCache();
        
        // Fetch field officer details for response
        Map<String, Object> userDetails = fetchUserDetails(fieldOfficer.getUserId());
        
        return AssignmentResponseDto.fromEntity(
                saved,
                buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                (String) userDetails.getOrDefault("phoneNumber", ""),
                fieldOfficer.getPincode()
        );
    }

    public Map<String, Object> getAssignmentSummariesForFarmers(List<Long> farmerUserIds) {
        if (farmerUserIds == null || farmerUserIds.isEmpty()) {
            return Map.of();
        }

        List<FieldOfficerAssignment> assignments = assignmentRepository.findByFarmerUserIdIn(farmerUserIds);
        Map<String, Object> result = new HashMap<>();

        for (Long farmerUserId : farmerUserIds) {
            List<FieldOfficerAssignment> perFarmer = assignments.stream()
                    .filter(a -> farmerUserId.equals(a.getFarmerUserId()))
                    .collect(Collectors.toList());

            boolean hasGlobalAssignment = perFarmer.stream().anyMatch(a ->
                    a.getFarmId() == null && a.getStatus() != FieldOfficerAssignment.AssignmentStatus.CANCELLED);

            int assignedFarmsCount = hasGlobalAssignment
                    ? 0
                    : (int) perFarmer.stream()
                            .filter(a -> a.getFarmId() != null && a.getStatus() != FieldOfficerAssignment.AssignmentStatus.CANCELLED)
                            .map(FieldOfficerAssignment::getFarmId)
                            .distinct()
                            .count();

            Map<String, Object> summary = new HashMap<>();
            summary.put("assignedFarmsCount", assignedFarmsCount);
            summary.put("hasGlobalAssignment", hasGlobalAssignment);
            result.put(String.valueOf(farmerUserId), summary);
        }

        return result;
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
    /**
     * Get assignments for a farmer with optimized batch fetching.
     * Uses batch queries to eliminate N+1 problems.
     */
    public List<AssignmentResponseDto> getAssignmentsForFarmer(Long farmerUserId) {
        log.info("Getting assignments for farmer userId: {}", farmerUserId);

        List<FieldOfficerAssignment> assignments = assignmentRepository.findByFarmerUserId(farmerUserId);

        if (assignments.isEmpty()) {
            return Collections.emptyList();
        }

        // Batch fetch all field officers
        List<Long> fieldOfficerIds = assignments.stream()
                .map(FieldOfficerAssignment::getFieldOfficerId)
                .distinct()
                .collect(Collectors.toList());

        Map<Long, FieldOfficer> fieldOfficerMap = fieldOfficerRepository.findAllById(fieldOfficerIds)
                .stream()
                .collect(Collectors.toMap(FieldOfficer::getId, fo -> fo));

        // Batch fetch all user details
        List<Long> userIds = fieldOfficerMap.values().stream()
                .map(FieldOfficer::getUserId)
                .distinct()
                .collect(Collectors.toList());

        Map<Long, Map<String, Object>> userDetailsMap = fetchUserDetailsBatch(userIds);

        // Build response DTOs
        return assignments.stream()
                .map(assignment -> {
                    FieldOfficer fieldOfficer = fieldOfficerMap.get(assignment.getFieldOfficerId());

                    if (fieldOfficer == null) {
                        log.warn("Field officer not found for assignment ID: {}", assignment.getId());
                        return AssignmentResponseDto.fromEntity(assignment, "Unknown", "", "", null, null, null, null);
                    }

                    Map<String, Object> userDetails = userDetailsMap.getOrDefault(fieldOfficer.getUserId(), new HashMap<>());

                    return AssignmentResponseDto.fromEntity(
                            assignment,
                            buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                            (String) userDetails.getOrDefault("phoneNumber", ""),
                            fieldOfficer.getPincode(),
                            null, // farmerName - not needed for farmer view
                            null, // farmerPhone - not needed for farmer view
                            null, // farmName - not needed for farmer view
                            null  // farmLocation - not needed for farmer view
                    );
                })
                .collect(Collectors.toList());
    }

    /**
     * Get assignments for a farmer (paginated version).
     */
    public Map<String, Object> getAssignmentsForFarmerPaged(Long farmerUserId, int page, int size) {
        log.info("Getting paginated assignments for farmer userId: {}", farmerUserId);

        Pageable pageable = PageRequest.of(page, size);
        Page<FieldOfficerAssignment> assignmentPage = assignmentRepository.findByFarmerUserId(farmerUserId, pageable);

        if (assignmentPage.isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("assignments", Collections.emptyList());
            response.put("currentPage", page);
            response.put("totalPages", 0);
            response.put("totalElements", 0L);
            response.put("pageSize", size);
            response.put("hasNext", false);
            response.put("hasPrevious", false);
            return response;
        }

        List<FieldOfficerAssignment> assignments = assignmentPage.getContent();

        // Batch fetch all field officers
        List<Long> fieldOfficerIds = assignments.stream()
                .map(FieldOfficerAssignment::getFieldOfficerId)
                .distinct()
                .collect(Collectors.toList());

        Map<Long, FieldOfficer> fieldOfficerMap = fieldOfficerRepository.findAllById(fieldOfficerIds)
                .stream()
                .collect(Collectors.toMap(FieldOfficer::getId, fo -> fo));

        // Batch fetch all user details
        List<Long> userIds = fieldOfficerMap.values().stream()
                .map(FieldOfficer::getUserId)
                .distinct()
                .collect(Collectors.toList());

        Map<Long, Map<String, Object>> userDetailsMap = fetchUserDetailsBatch(userIds);

        // Build response DTOs
        List<AssignmentResponseDto> dtos = assignments.stream()
                .map(assignment -> {
                    FieldOfficer fieldOfficer = fieldOfficerMap.get(assignment.getFieldOfficerId());

                    if (fieldOfficer == null) {
                        log.warn("Field officer not found for assignment ID: {}", assignment.getId());
                        return AssignmentResponseDto.fromEntity(assignment, "Unknown", "", "", null, null, null, null);
                    }

                    Map<String, Object> userDetails = userDetailsMap.getOrDefault(fieldOfficer.getUserId(), new HashMap<>());

                    return AssignmentResponseDto.fromEntity(
                            assignment,
                            buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName()),
                            (String) userDetails.getOrDefault("phoneNumber", ""),
                            fieldOfficer.getPincode(),
                            null, null, null, null
                    );
                })
                .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("assignments", dtos);
        response.put("currentPage", assignmentPage.getNumber());
        response.put("totalPages", assignmentPage.getTotalPages());
        response.put("totalElements", assignmentPage.getTotalElements());
        response.put("pageSize", assignmentPage.getSize());
        response.put("hasNext", assignmentPage.hasNext());
        response.put("hasPrevious", assignmentPage.hasPrevious());

        return response;
    }

    /**
     * Get all assignments for a field officer with farmer and farm details (for admin view).
     * Optimized with batch fetching to eliminate N+1 query problems.
     */
    public Page<AssignmentResponseDto> getAssignmentsForFieldOfficer(Long fieldOfficerId, Pageable pageable) {
        log.info("Getting assignments for field officer ID: {} (with farmer and farm details)", fieldOfficerId);
        
        Page<FieldOfficerAssignment> assignments = assignmentRepository.findByFieldOfficerId(fieldOfficerId, pageable);
        
        if (assignments.isEmpty()) {
            return assignments.map(a -> AssignmentResponseDto.fromEntity(a, "Unknown", "", "", null, null, null, null));
        }
        
        // Get field officer once (same for all assignments)
        FieldOfficer fieldOfficer = fieldOfficerRepository.findById(fieldOfficerId).orElse(null);
        Map<String, Object> fieldOfficerUserDetails = new HashMap<>();
        if (fieldOfficer != null) {
            fieldOfficerUserDetails = fetchUserDetails(fieldOfficer.getUserId());
        }
        
        // Batch fetch all farmer user details
        List<Long> farmerUserIds = assignments.getContent().stream()
                .map(FieldOfficerAssignment::getFarmerUserId)
                .distinct()
                .collect(Collectors.toList());
        
        Map<Long, Map<String, Object>> farmerUserDetailsMap = fetchUserDetailsBatch(farmerUserIds);
        Map<Long, List<Map<String, Object>>> farmerFarmsMap = new HashMap<>();

        for (Long farmerUserId : farmerUserIds) {
            try {
                farmerFarmsMap.put(farmerUserId, fetchFarmerFarms(farmerUserId));
            } catch (Exception e) {
                log.warn("Failed to fetch farms for farmer userId {}: {}", farmerUserId, e.getMessage());
                farmerFarmsMap.put(farmerUserId, Collections.emptyList());
            }
        }
        
        final FieldOfficer finalFieldOfficer = fieldOfficer;
        final Map<String, Object> finalFieldOfficerUserDetails = fieldOfficerUserDetails;
        
        return assignments.map(assignment -> {
            if (finalFieldOfficer == null) {
                return AssignmentResponseDto.fromEntity(assignment, "Unknown", "", "", null, null, null, null);
            }
            
            // Get farmer details from batch map
            Map<String, Object> farmerUserDetails = farmerUserDetailsMap.getOrDefault(
                    assignment.getFarmerUserId(), new HashMap<>());
            
            String farmerName = buildFullName(
                    (String) farmerUserDetails.getOrDefault("firstName", ""),
                    (String) farmerUserDetails.getOrDefault("lastName", ""));
            if (farmerName.trim().isEmpty()) {
                farmerName = (String) farmerUserDetails.getOrDefault("username", "Unknown Farmer");
            }
            String farmerPhone = (String) farmerUserDetails.getOrDefault("phoneNumber", "");
            
            // Fetch farm details if farmId is specified
            String farmName = null;
            String farmLocation = null;
            if (assignment.getFarmId() != null) {
                try {
                    List<Map<String, Object>> farms = farmerFarmsMap.getOrDefault(
                            assignment.getFarmerUserId(),
                            Collections.emptyList());
                    Optional<Map<String, Object>> farmOpt = farms.stream()
                            .filter(farm -> {
                                Object farmIdObj = farm.get("farmId");
                                if (farmIdObj == null) {
                                    farmIdObj = farm.get("id");
                                }
                                if (farmIdObj instanceof Number) {
                                    return ((Number) farmIdObj).longValue() == assignment.getFarmId();
                                }
                                return String.valueOf(farmIdObj).equals(String.valueOf(assignment.getFarmId()));
                            })
                            .findFirst();
                    
                    if (farmOpt.isPresent()) {
                        Map<String, Object> farm = farmOpt.get();
                        farmName = (String) farm.getOrDefault("farmName", "Unknown Farm");
                        String village = (String) farm.getOrDefault("village", "");
                        String district = (String) farm.getOrDefault("district", "");
                        String state = (String) farm.getOrDefault("state", "");
                        farmLocation = String.format("%s, %s, %s", village, district, state).trim();
                    }
                } catch (Exception e) {
                    log.warn("Failed to fetch farm details for farmId {}: {}", assignment.getFarmId(), e.getMessage());
                }
            }
            
            AssignmentResponseDto dto = AssignmentResponseDto.fromEntity(
                    assignment,
                    buildFullName(finalFieldOfficer.getFirstName(), finalFieldOfficer.getLastName()),
                    (String) finalFieldOfficerUserDetails.getOrDefault("phoneNumber", ""),
                    finalFieldOfficer.getPincode()
            );
            
            // Set farmer and farm details
            dto.setFarmerName(farmerName);
            dto.setFarmerPhone(farmerPhone);
            dto.setFarmName(farmName);
            dto.setFarmLocation(farmLocation);
            
            return dto;
        });
    }

    private Map<Long, Integer> getAssignedFarmCounts(List<Long> fieldOfficerIds) {
        if (fieldOfficerIds == null || fieldOfficerIds.isEmpty()) {
            return Collections.emptyMap();
        }

        try {
            List<Object[]> rows = assignmentRepository.countActiveFarmAssignmentsByFieldOfficerIds(fieldOfficerIds);
            Map<Long, Integer> counts = new HashMap<>();
            for (Object[] row : rows) {
                if (row.length >= 2 && row[0] != null && row[1] != null) {
                    Long fieldOfficerId = ((Number) row[0]).longValue();
                    Integer count = ((Number) row[1]).intValue();
                    counts.put(fieldOfficerId, count);
                }
            }
            return counts;
        } catch (Exception e) {
            log.warn("Failed to batch count assigned farms. Falling back to defaults: {}", e.getMessage());
            return Collections.emptyMap();
        }
    }

    /**
     * Get assignments with farm details for a field officer (by userId).
     * Used by field officer app to see their assigned farms.
     * Optimized with batch fetching to eliminate N+1 query problems.
     */
    public List<com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto> getAssignmentsWithFarmsForFieldOfficer(Long fieldOfficerUserId) {
        return getAssignmentsWithFarmsForFieldOfficer(fieldOfficerUserId, 0, 1000);
        }

        /**
         * Paginated variant used to reduce payload and repeated remote calls.
         */
        public List<com.krushikranti.fieldofficer.dto.FieldOfficerAssignmentDto> getAssignmentsWithFarmsForFieldOfficer(
            Long fieldOfficerUserId,
            int page,
            int size) {
        log.info("Getting assignments with farms for field officer userId: {}", fieldOfficerUserId);
        
        // Find field officer by userId
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException("Field officer not found with userId: " + fieldOfficerUserId));

        int safePage = Math.max(0, page);
        int safeSize = Math.min(Math.max(1, size), 1000);
        
        // Get assignments for this field officer (bounded for performance)
        Page<FieldOfficerAssignment> assignmentPage = assignmentRepository.findByFieldOfficerId(
                fieldOfficer.getId(), 
            PageRequest.of(safePage, safeSize));
        List<FieldOfficerAssignment> assignments = assignmentPage.getContent();
        
        if (assignments.isEmpty()) {
            return Collections.emptyList();
        }
        
        log.info("Found {} assignments for field officer userId: {}", assignments.size(), fieldOfficerUserId);
        
        // Batch fetch all farmer user details
        List<Long> farmerUserIds = assignments.stream()
                .map(FieldOfficerAssignment::getFarmerUserId)
                .distinct()
                .collect(Collectors.toList());
        
        Map<Long, Map<String, Object>> farmerUserDetailsMap = fetchUserDetailsBatch(farmerUserIds);

        // Fetch farms once per farmer instead of once per assignment.
        Map<Long, List<Map<String, Object>>> farmerFarmsMap = new HashMap<>();
        for (Long farmerUserId : farmerUserIds) {
            try {
                farmerFarmsMap.put(farmerUserId, fetchFarmerFarms(farmerUserId));
            } catch (Exception e) {
                log.warn("Failed to fetch farms for farmer userId {}: {}", farmerUserId, e.getMessage());
                farmerFarmsMap.put(farmerUserId, Collections.emptyList());
            }
        }

        // Fetch verifications only for farms that are relevant to this page.
        Set<Long> relevantFarmIds = farmerFarmsMap.values().stream()
                .flatMap(List::stream)
                .map(farm -> {
                    Object farmIdObj = farm.get("farmId");
                    if (farmIdObj == null) {
                        farmIdObj = farm.get("id");
                    }
                    if (farmIdObj instanceof Number) {
                        return ((Number) farmIdObj).longValue();
                    }
                    if (farmIdObj != null) {
                        try {
                            return Long.parseLong(farmIdObj.toString());
                        } catch (NumberFormatException ignored) {
                            return null;
                        }
                    }
                    return null;
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Map<Long, FarmVerification> verificationMap;
        if (relevantFarmIds.isEmpty()) {
            verificationMap = Collections.emptyMap();
        } else {
            verificationMap = verificationRepository
                    .findByFieldOfficerIdAndFarmIdIn(fieldOfficer.getId(), new ArrayList<>(relevantFarmIds))
                    .stream()
                .collect(Collectors.toMap(
                        FarmVerification::getFarmId, 
                        v -> v,
                        (v1, v2) -> v1)); // If duplicate farmIds, keep first
        }
        
        final Long fieldOfficerId = fieldOfficer.getId();
        final Map<Long, FarmVerification> finalVerificationMap = verificationMap;
        
        // Build response DTOs
        List<FieldOfficerAssignmentDto> result = assignments.stream()
                .map(assignment -> {
                    try {
                        // Get farmer details from batch map
                        Map<String, Object> farmerUserDetails = farmerUserDetailsMap.getOrDefault(
                                assignment.getFarmerUserId(), new HashMap<>());
                        
                        String farmerNameTemp = buildFullName(
                                (String) farmerUserDetails.getOrDefault("firstName", ""),
                                (String) farmerUserDetails.getOrDefault("lastName", ""));
                        if (farmerNameTemp.trim().isEmpty()) {
                            farmerNameTemp = (String) farmerUserDetails.getOrDefault("username", "Unknown Farmer");
                        }
                        final String farmerName = farmerNameTemp;
                        String farmerPhone = (String) farmerUserDetails.getOrDefault("phoneNumber", "");
                        
                        // Reuse already-fetched farms for this farmer.
                        List<Map<String, Object>> farms;
                        try {
                            farms = farmerFarmsMap.getOrDefault(
                                    assignment.getFarmerUserId(),
                                    Collections.emptyList());
                            
                            // Filter farms by assignment.farmId if specified
                            if (assignment.getFarmId() != null) {
                                farms = farms.stream()
                                        .filter(farm -> {
                                            Object farmIdObj = farm.get("farmId");
                                            if (farmIdObj == null) {
                                                farmIdObj = farm.get("id");
                                            }
                                            if (farmIdObj instanceof Number) {
                                                return ((Number) farmIdObj).longValue() == assignment.getFarmId();
                                            }
                                            return String.valueOf(farmIdObj).equals(String.valueOf(assignment.getFarmId()));
                                        })
                                        .collect(Collectors.toList());
                            }
                        } catch (Exception e) {
                            log.error("Error fetching farms for farmer userId {} (assignment {}): {}", 
                                    assignment.getFarmerUserId(), assignment.getId(), e.getMessage());
                            farms = Collections.emptyList();
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
                                        
                                        // Get farm ID for verification lookup
                                        Object farmIdObj = farmWithLocation.get("farmId");
                                        if (farmIdObj == null) {
                                            farmIdObj = farmWithLocation.get("id");
                                        }
                                        
                                        // Check verification status from batch map
                                        boolean isVerified = false;
                                        String verificationStatus = "PENDING";
                                        
                                        if (farmIdObj != null) {
                                            Long farmId;
                                            if (farmIdObj instanceof Number) {
                                                farmId = ((Number) farmIdObj).longValue();
                                            } else {
                                                try {
                                                    farmId = Long.parseLong(farmIdObj.toString());
                                                } catch (NumberFormatException e) {
                                                    farmId = null;
                                                }
                                            }
                                            
                                            if (farmId != null) {
                                                FarmVerification verification = finalVerificationMap.get(farmId);
                                                if (verification != null) {
                                                    FarmVerification.VerificationStatus status = verification.getVerificationStatus();
                                                    verificationStatus = status.name();
                                                    
                                                    if (status == FarmVerification.VerificationStatus.VERIFIED) {
                                                        isVerified = true;
                                                    }
                                                }
                                            }
                                        }
                                        
                                        farmWithLocation.put("status", verificationStatus);
                                        farmWithLocation.put("isVerified", isVerified);
                                        farmWithLocation.put("assignmentId", assignment.getId());
                                        
                                        // Ensure farmName field exists
                                        if (!farmWithLocation.containsKey("farmName") && farmWithLocation.containsKey("farm_name")) {
                                            farmWithLocation.put("farmName", farmWithLocation.get("farm_name"));
                                        }
                                        // Ensure farmId field exists
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
                        
                        return FieldOfficerAssignmentDto.builder()
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
                    } catch (Exception e) {
                        log.error("Error processing assignment {}: {}", assignment.getId(), e.getMessage(), e);
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

        /**
         * Paginated assignments payload with metadata for field-officer app.
         */
        public Map<String, Object> getAssignmentsWithFarmsForFieldOfficerPaged(
            Long fieldOfficerUserId,
            int page,
            int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.min(Math.max(1, size), 1000);

        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
            .orElseThrow(() -> new IllegalArgumentException("Field officer not found with userId: " + fieldOfficerUserId));

        Page<FieldOfficerAssignment> assignmentPage = assignmentRepository.findByFieldOfficerId(
            fieldOfficer.getId(),
            PageRequest.of(safePage, safeSize));

        List<FieldOfficerAssignmentDto> assignments = getAssignmentsWithFarmsForFieldOfficer(
            fieldOfficerUserId,
            safePage,
            safeSize);

        Map<String, Object> response = new HashMap<>();
        response.put("assignments", assignments);
        response.put("currentPage", assignmentPage.getNumber());
        response.put("totalPages", assignmentPage.getTotalPages());
        response.put("totalElements", assignmentPage.getTotalElements());
        response.put("pageSize", assignmentPage.getSize());
        response.put("hasNext", assignmentPage.hasNext());
        response.put("hasPrevious", assignmentPage.hasPrevious());

        return response;
        }

            /**
             * Lightweight dashboard summary for the logged-in field officer.
             * Uses count queries to avoid loading assignments payload for home cards.
             */
            public Map<String, Object> getFieldOfficerAssignmentSummary(Long fieldOfficerUserId) {
            log.info("Getting assignment summary for field officer userId: {}", fieldOfficerUserId);

            FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(fieldOfficerUserId)
                .orElseThrow(() -> new IllegalArgumentException("Field officer not found with userId: " + fieldOfficerUserId));

            Long fieldOfficerId = fieldOfficer.getId();

            long totalAssignments = assignmentRepository.countByFieldOfficerIdAndStatusNot(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.CANCELLED);
            long activeFarmAssignments = assignmentRepository.countByFieldOfficerIdAndFarmIdIsNotNullAndStatusNot(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.CANCELLED);
            long assignedFarms = assignmentRepository.countByFieldOfficerIdAndFarmIdIsNotNullAndStatus(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.ASSIGNED);
            long inProgressFarms = assignmentRepository.countByFieldOfficerIdAndFarmIdIsNotNullAndStatus(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.IN_PROGRESS);
            long completedFarms = assignmentRepository.countByFieldOfficerIdAndFarmIdIsNotNullAndStatus(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.COMPLETED);
            long verifiedFarms = verificationRepository.countByFieldOfficerIdAndVerificationStatus(
                fieldOfficerId,
                FarmVerification.VerificationStatus.VERIFIED);

            Map<String, Object> summary = new HashMap<>();
            summary.put("fieldOfficerId", fieldOfficerId);
            summary.put("totalAssignments", totalAssignments);
            summary.put("activeFarmAssignments", activeFarmAssignments);
            summary.put("assignedFarms", assignedFarms);
            summary.put("inProgressFarms", inProgressFarms);
            summary.put("completedFarms", completedFarms);
            summary.put("verifiedFarms", verifiedFarms);
            summary.put("pendingFarms", assignedFarms + inProgressFarms);

            return summary;
            }

    // ==================== Helper Methods ====================

    /**
     * Fetch all farms for a farmer from farmer-service.
     * Optimized to use direct admin endpoint instead of fetching all farmers.
     */
    private List<Map<String, Object>> fetchFarmerFarms(Long farmerUserId) {
        try {
            log.debug("Fetching farms for farmer userId: {}", farmerUserId);
            
            // First, get farmer by userId to find farmerId
            // Call admin endpoint to get farmer list and find the one with matching userId
            Map<String, Object> listResponse;
            try {
                String url = farmerServiceUrl + "/admin/farmers?page=0&size=1000";
                listResponse = webClientBuilder.build()
                        .get()
                        .uri(url)
                        .header("X-User-Id", "1")
                        .header("X-User-Roles", "ADMIN")
                        .retrieve()
                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                        .block();
            } catch (Exception e) {
                log.error("Error fetching farmer list for userId {}: {}", farmerUserId, e.getMessage());
                return Collections.emptyList();
            }
            
            if (listResponse == null) {
                log.error("No response from farmer-service list endpoint for userId: {}", farmerUserId);
                return Collections.emptyList();
            }
            
            // Unwrap ApiResponse and find farmer
            Object dataObj = listResponse.get("data");
            if (!(dataObj instanceof Map)) {
                log.error("Unexpected response structure from farmer-service for userId: {}", farmerUserId);
                return Collections.emptyList();
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) dataObj;
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmers = (List<Map<String, Object>>) data.get("farmers");
            
            if (farmers == null || farmers.isEmpty()) {
                log.warn("No farmers found in response for userId: {}", farmerUserId);
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
            Object farmerIdObj = farmer.get("farmerId");
            if (farmerIdObj == null) {
                log.warn("Farmer ID not found in farmer data for userId: {}", farmerUserId);
                return Collections.emptyList();
            }
            
            Long farmerId = ((Number) farmerIdObj).longValue();
            
            // Now get farmer detail with farms using direct endpoint
            String detailUrl = farmerServiceUrl + "/admin/farmers/" + farmerId;
            Map<String, Object> detailResponse;
            try {
                detailResponse = webClientBuilder.build()
                        .get()
                        .uri(detailUrl)
                        .header("X-User-Id", "1")
                        .header("X-User-Roles", "ADMIN")
                        .retrieve()
                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                        .block();
            } catch (Exception e) {
                log.error("Error fetching farmer detail for farmerId {}: {}", farmerId, e.getMessage());
                return Collections.emptyList();
            }
            
            if (detailResponse == null) {
                log.error("No response from farmer-service detail endpoint for farmerId: {}", farmerId);
                return Collections.emptyList();
            }
            
            // Extract farms from response
            Object detailDataObj = detailResponse.get("data");
            if (!(detailDataObj instanceof Map)) {
                log.error("Unexpected detail response structure for farmerId: {}", farmerId);
                return Collections.emptyList();
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> detailData = (Map<String, Object>) detailDataObj;
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> farmsList = (List<Map<String, Object>>) detailData.get("farms");
            
            if (farmsList == null || farmsList.isEmpty()) {
                log.debug("No farms found for farmerId: {}", farmerId);
                return Collections.emptyList();
            }
            
            // Convert farms to proper format
            List<Map<String, Object>> farmMaps = new java.util.ArrayList<>();
            for (Map<String, Object> farm : farmsList) {
                Map<String, Object> farmMap = new java.util.HashMap<>(farm);
                
                // Ensure farmName is present
                if (!farmMap.containsKey("farmName") && farmMap.containsKey("farm_name")) {
                    farmMap.put("farmName", farmMap.get("farm_name"));
                }
                // Ensure farmId is present
                if (!farmMap.containsKey("farmId")) {
                    if (farmMap.containsKey("id")) {
                        farmMap.put("farmId", farmMap.get("id"));
                    } else if (farmMap.containsKey("farm_id")) {
                        farmMap.put("farmId", farmMap.get("farm_id"));
                    }
                }
                
                farmMaps.add(farmMap);
            }
            
            log.debug("Fetched {} farms for farmer userId: {}", farmMaps.size(), farmerUserId);
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

    /**
     * Batch fetch user details using the new batch endpoint for performance optimization.
     * This eliminates N+1 query problems by fetching all users in a single API call.
     */
    private Map<Long, Map<String, Object>> fetchUserDetailsBatch(List<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return new HashMap<>();
        }
        
        Map<Long, Map<String, Object>> userMap = new HashMap<>();
        
        try {
            // Use the new batch endpoint
            Map<String, Object> requestBody = Map.of("userIds", userIds);
            
            Map<String, Object> response = webClientBuilder.build()
                    .post()
                    .uri(authServiceUrl + "/auth/users/batch")
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (response != null && response.containsKey("data")) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> users = (List<Map<String, Object>>) response.get("data");
                
                for (Map<String, Object> user : users) {
                    Object idObj = user.get("id");
                    if (idObj != null) {
                        Long userId = idObj instanceof Number 
                                ? ((Number) idObj).longValue() 
                                : Long.parseLong(idObj.toString());
                        userMap.put(userId, user);
                    }
                }
                
                log.debug("Batch fetched {} users out of {} requested", userMap.size(), userIds.size());
            }
        } catch (Exception e) {
            log.warn("Failed to batch fetch user details, falling back to individual calls: {}", e.getMessage());
            // Fallback to individual calls if batch fails
            for (Long userId : userIds) {
                try {
                    Map<String, Object> userDetails = fetchUserDetails(userId);
                    userMap.put(userId, userDetails);
                } catch (Exception ex) {
                    log.warn("Failed to fetch user details for userId {}: {}", userId, ex.getMessage());
                }
            }
        }
        
        return userMap;
    }

    private String buildFullName(String firstName, String lastName) {
        String fn = firstName != null ? firstName : "";
        String ln = lastName != null ? lastName : "";
        return (fn + " " + ln).trim();
    }

    /**
     * Count the number of farms assigned to a field officer.
     * Only counts assignments with farmId (not null) and status != CANCELLED.
     * This matches the logic used in FieldOfficerService for consistency.
     */
    private Integer countAssignedFarms(Long fieldOfficerId) {
        try {
            return Math.toIntExact(assignmentRepository.countByFieldOfficerIdAndFarmIdIsNotNullAndStatusNot(
                fieldOfficerId,
                FieldOfficerAssignment.AssignmentStatus.CANCELLED));
        } catch (Exception e) {
            log.warn("Failed to count assigned farms for field officer ID {}: {}", fieldOfficerId, e.getMessage());
            return 0;
        }
    }

    private void invalidateAdminFarmerCache() {
        try {
            webClientBuilder.build()
                    .post()
                    .uri(farmerServiceUrl + "/admin/farmers/cache/invalidate")
                    .header("X-User-Id", "1")
                    .header("X-User-Roles", "SYSTEM")
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        } catch (Exception e) {
            log.warn("Failed to invalidate farmer admin cache after assignment change: {}", e.getMessage());
        }
    }
}

