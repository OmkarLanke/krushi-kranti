package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.admin.AdminFarmerDetailDto;
import com.krushikranti.farmer.dto.admin.AdminFarmerListResponse;
import com.krushikranti.farmer.dto.admin.AdminFarmerSummaryDto;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Crop;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmerRepository;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.CropRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service for admin farmer management operations.
 * Aggregates data from farmer, KYC, and subscription services.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminFarmerService {

    private final FarmerRepository farmerRepository;
    private final FarmRepository farmRepository;
    private final CropRepository cropRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.kyc-service.url:http://localhost:4014}")
    private String kycServiceUrl;

    @Value("${services.subscription-service.url:http://localhost:4013}")
    private String subscriptionServiceUrl;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    @Value("${services.field-officer-service.url:http://localhost:4015}")
    private String fieldOfficerServiceUrl;

    /**
     * Get paginated list of all farmers with summary info
     */
    public AdminFarmerListResponse getAllFarmers(int page, int size, String search, String kycStatus, String subscriptionStatus, String pincode) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        
        Page<Farmer> farmerPage;
        
        if (search != null && !search.trim().isEmpty()) {
            farmerPage = farmerRepository.searchFarmers(search.trim(), pageable);
        } else {
            farmerPage = farmerRepository.findAll(pageable);
        }

        // Filter by pincode if provided
        List<Farmer> filteredFarmers = farmerPage.getContent();
        if (pincode != null && !pincode.trim().isEmpty()) {
            filteredFarmers = filteredFarmers.stream()
                    .filter(farmer -> farmer.getPincode() != null && 
                            farmer.getPincode().equalsIgnoreCase(pincode.trim()))
                    .collect(Collectors.toList());
        }

        List<Long> userIds = filteredFarmers.stream()
                .map(Farmer::getUserId)
                .collect(Collectors.toList());

        // Fetch KYC status for all users
        Map<Long, Map<String, Object>> kycMap = fetchKycStatusBatch(userIds);
        
        // Fetch subscription status for all users
        Map<Long, Map<String, Object>> subscriptionMap = fetchSubscriptionStatusBatch(userIds);
        
        // Fetch user details (username, email, phone) from auth service
        Map<Long, Map<String, Object>> userMap = fetchUserDetailsBatch(userIds);

        // Fetch assignment summaries for all farmers
        Map<Long, AssignmentSummary> assignmentMap = fetchAssignmentSummariesBatch(userIds);

        List<AdminFarmerSummaryDto> summaries = new ArrayList<>();
        
        for (Farmer farmer : filteredFarmers) {
            Map<String, Object> kycInfo = kycMap.getOrDefault(farmer.getUserId(), Map.of());
            Map<String, Object> subInfo = subscriptionMap.getOrDefault(farmer.getUserId(), Map.of());
            Map<String, Object> userInfo = userMap.getOrDefault(farmer.getUserId(), Map.of());
            
            String currentKycStatus = (String) kycInfo.getOrDefault("kycStatus", "PENDING");
            String currentSubStatus = (String) subInfo.getOrDefault("subscriptionStatus", "PENDING");
            
            // Apply filters
            if (kycStatus != null && !kycStatus.isEmpty() && !kycStatus.equalsIgnoreCase(currentKycStatus)) {
                continue;
            }
            if (subscriptionStatus != null && !subscriptionStatus.isEmpty() && !subscriptionStatus.equalsIgnoreCase(currentSubStatus)) {
                continue;
            }
            
            // Count farms
            long farmCount = farmRepository.countByFarmerId(farmer.getId());
            long verifiedFarmCount = farmRepository.countByFarmerIdAndIsVerifiedTrue(farmer.getId());
            
            // Get assignment summary
            AssignmentSummary assignmentSummary = assignmentMap.getOrDefault(farmer.getUserId(), 
                    AssignmentSummary.empty((int) farmCount));
            
            // Use farmCount from repository if assignment summary doesn't have it
            int totalFarmsForAssignment = assignmentSummary.totalFarmsCount > 0 
                    ? assignmentSummary.totalFarmsCount 
                    : (int) farmCount;
            
            AdminFarmerSummaryDto summary = AdminFarmerSummaryDto.builder()
                    .farmerId(farmer.getId())
                    .userId(farmer.getUserId())
                    .fullName(buildFullName(farmer.getFirstName(), farmer.getLastName()))
                    .username((String) userInfo.getOrDefault("username", ""))
                    .phoneNumber((String) userInfo.getOrDefault("phoneNumber", ""))
                    .email((String) userInfo.getOrDefault("email", ""))
                    .village(farmer.getVillage())
                    .district(farmer.getDistrict())
                    .state(farmer.getState())
                    .pincode(farmer.getPincode())
                    .isProfileComplete(isProfileComplete(farmer))
                    .kycStatus(currentKycStatus)
                    .subscriptionStatus(currentSubStatus)
                    .farmCount((int) farmCount)
                    .verifiedFarmCount((int) verifiedFarmCount)
                    .assignedFarmsCount(assignmentSummary.assignedFarmsCount)
                    .totalFarmsCount(totalFarmsForAssignment)
                    .hasAllFarmsAssigned(assignmentSummary.hasAllFarmsAssigned)
                    .hasPartialAssignment(assignmentSummary.hasPartialAssignment)
                    .registeredAt(farmer.getCreatedAt())
                    .lastUpdatedAt(farmer.getUpdatedAt())
                    .build();
            
            summaries.add(summary);
        }

        // Build stats
        AdminFarmerListResponse.AdminDashboardStats stats = buildDashboardStats();

        return AdminFarmerListResponse.builder()
                .farmers(summaries)
                .currentPage(farmerPage.getNumber())
                .totalPages(farmerPage.getTotalPages())
                .totalElements(farmerPage.getTotalElements())
                .pageSize(farmerPage.getSize())
                .hasNext(farmerPage.hasNext())
                .hasPrevious(farmerPage.hasPrevious())
                .stats(stats)
                .build();
    }

    /**
     * Get detailed information for a single farmer
     */
    public Optional<AdminFarmerDetailDto> getFarmerDetail(Long farmerId) {
        Optional<Farmer> farmerOpt = farmerRepository.findById(farmerId);
        
        if (farmerOpt.isEmpty()) {
            return Optional.empty();
        }
        
        Farmer farmer = farmerOpt.get();
        
        // Fetch user details
        Map<String, Object> userInfo = fetchUserDetails(farmer.getUserId());
        
        // Fetch KYC details
        Map<String, Object> kycInfo = fetchKycStatus(farmer.getUserId());
        
        // Fetch subscription details
        Map<String, Object> subInfo = fetchSubscriptionStatus(farmer.getUserId());
        
        // Fetch farms
        List<Farm> farms = farmRepository.findByFarmerId(farmer.getId());

        // Fetch crops (across all farms for this farmer)
        List<Crop> crops = cropRepository.findByFarmerUserIdWithDetails(farmer.getUserId());
        
        // Build profile info
        AdminFarmerDetailDto.ProfileInfo profileInfo = AdminFarmerDetailDto.ProfileInfo.builder()
                .firstName(farmer.getFirstName())
                .lastName(farmer.getLastName())
                .fullName(buildFullName(farmer.getFirstName(), farmer.getLastName()))
                .username((String) userInfo.getOrDefault("username", ""))
                .email((String) userInfo.getOrDefault("email", ""))
                .phoneNumber((String) userInfo.getOrDefault("phoneNumber", ""))
                .alternatePhone(farmer.getAlternatePhone())
                .dateOfBirth(farmer.getDateOfBirth())
                .gender(farmer.getGender() != null ? farmer.getGender().name() : null)
                .pincode(farmer.getPincode())
                .village(farmer.getVillage())
                .taluka(farmer.getTaluka())
                .district(farmer.getDistrict())
                .state(farmer.getState())
                .isProfileComplete(isProfileComplete(farmer))
                .createdAt(farmer.getCreatedAt())
                .updatedAt(farmer.getUpdatedAt())
                .build();
        
        // Build KYC info
        AdminFarmerDetailDto.KycInfo kycInfoDto = buildKycInfo(kycInfo);
        
        // Build subscription info
        AdminFarmerDetailDto.SubscriptionInfo subInfoDto = buildSubscriptionInfo(subInfo);
        
        // Build farm list
        List<AdminFarmerDetailDto.FarmInfo> farmInfoList = farms.stream()
                .map(this::buildFarmInfo)
                .collect(Collectors.toList());

        // Build crop list
        List<AdminFarmerDetailDto.CropInfo> cropInfoList = crops.stream()
                .map(this::buildCropInfo)
                .collect(Collectors.toList());
        
        return Optional.of(AdminFarmerDetailDto.builder()
                .farmerId(farmer.getId())
                .userId(farmer.getUserId())
                .profile(profileInfo)
                .kyc(kycInfoDto)
                .subscription(subInfoDto)
                .farms(farmInfoList)
                .crops(cropInfoList)
                .assignment(null) // Will be implemented when field officer feature is added
                .build());
    }

    /**
     * Get dashboard statistics
     */
    public AdminFarmerListResponse.AdminDashboardStats getDashboardStats() {
        return buildDashboardStats();
    }

    // ==================== Helper Methods ====================

    private String buildFullName(String firstName, String lastName) {
        String fn = firstName != null ? firstName : "";
        String ln = lastName != null ? lastName : "";
        return (fn + " " + ln).trim();
    }

    private boolean isProfileComplete(Farmer farmer) {
        return farmer.getFirstName() != null && !farmer.getFirstName().isEmpty()
                && farmer.getLastName() != null && !farmer.getLastName().isEmpty()
                && farmer.getPincode() != null && !farmer.getPincode().isEmpty()
                && farmer.getVillage() != null && !farmer.getVillage().isEmpty();
    }

    private AdminFarmerListResponse.AdminDashboardStats buildDashboardStats() {
        long totalFarmers = farmerRepository.count();
        long totalFarms = farmRepository.count();
        long verifiedFarms = farmRepository.countByIsVerifiedTrue();
        
        // These would ideally come from KYC and Subscription services
        // For now, we'll use placeholder values
        return AdminFarmerListResponse.AdminDashboardStats.builder()
                .totalFarmers(totalFarmers)
                .pendingKyc(0)      // Will be fetched from KYC service
                .verifiedKyc(0)     // Will be fetched from KYC service
                .activeSubscriptions(0) // Will be fetched from Subscription service
                .pendingSubscriptions(0) // Will be fetched from Subscription service
                .totalFarms(totalFarms)
                .verifiedFarms(verifiedFarms)
                .build();
    }

    private AdminFarmerDetailDto.KycInfo buildKycInfo(Map<String, Object> kycInfo) {
        return AdminFarmerDetailDto.KycInfo.builder()
                .status((String) kycInfo.getOrDefault("kycStatus", "PENDING"))
                .aadhaarVerified((Boolean) kycInfo.getOrDefault("aadhaarVerified", false))
                .aadhaarName((String) kycInfo.get("aadhaarName"))
                .aadhaarNumberMasked((String) kycInfo.get("aadhaarNumberMasked"))
                .panVerified((Boolean) kycInfo.getOrDefault("panVerified", false))
                .panName((String) kycInfo.get("panName"))
                .panNumberMasked((String) kycInfo.get("panNumberMasked"))
                .bankVerified((Boolean) kycInfo.getOrDefault("bankVerified", false))
                .bankName((String) kycInfo.get("bankName"))
                .bankAccountHolderName((String) kycInfo.get("bankAccountHolderName"))
                .bankAccountMasked((String) kycInfo.get("bankAccountMasked"))
                .bankIfsc((String) kycInfo.get("bankIfsc"))
                .build();
    }

    private AdminFarmerDetailDto.SubscriptionInfo buildSubscriptionInfo(Map<String, Object> subInfo) {
        return AdminFarmerDetailDto.SubscriptionInfo.builder()
                .subscriptionId(subInfo.get("subscriptionId") != null ? ((Number) subInfo.get("subscriptionId")).longValue() : null)
                .status((String) subInfo.getOrDefault("subscriptionStatus", "PENDING"))
                .paymentStatus((String) subInfo.get("paymentStatus"))
                .paymentTransactionId((String) subInfo.get("paymentTransactionId"))
                .build();
    }

    private AdminFarmerDetailDto.FarmInfo buildFarmInfo(Farm farm) {
        return AdminFarmerDetailDto.FarmInfo.builder()
                .farmId(farm.getId())
                .farmName(farm.getFarmName())
                .farmType(farm.getFarmType() != null ? farm.getFarmType().name() : null)
                .totalAreaAcres(farm.getTotalAreaAcres())
                .pincode(farm.getPincode())
                .village(farm.getVillage())
                .district(farm.getDistrict())
                .taluka(farm.getTaluka())
                .state(farm.getState())
                .soilType(farm.getSoilType() != null ? farm.getSoilType().name() : null)
                .irrigationType(farm.getIrrigationType() != null ? farm.getIrrigationType().name() : null)
                .landOwnership(farm.getLandOwnership() != null ? farm.getLandOwnership().name() : null)
                .surveyNumber(farm.getSurveyNumber())
                .landRegistrationNumber(farm.getLandRegistrationNumber())
                .pattaNumber(farm.getPattaNumber())
                .estimatedLandValue(farm.getEstimatedLandValue())
                .encumbranceStatus(farm.getEncumbranceStatus() != null ? farm.getEncumbranceStatus().name() : null)
                .encumbranceRemarks(farm.getEncumbranceRemarks())
                .landDocumentUrl(farm.getLandDocumentUrl())
                .surveyMapUrl(farm.getSurveyMapUrl())
                .registrationCertificateUrl(farm.getRegistrationCertificateUrl())
                .isVerified(farm.getIsVerified())
                .verifiedByOfficerId(farm.getVerifiedBy())
                .verifiedAt(farm.getVerifiedAt())
                .verificationRemarks(farm.getVerificationRemarks())
                .createdAt(farm.getCreatedAt())
                .build();
    }

    private AdminFarmerDetailDto.CropInfo buildCropInfo(Crop crop) {
        return AdminFarmerDetailDto.CropInfo.builder()
                .cropId(crop.getId())
                .farmId(crop.getFarm() != null ? crop.getFarm().getId() : null)
                .farmName(crop.getFarm() != null ? crop.getFarm().getFarmName() : null)
                .cropTypeId(crop.getCropName() != null && crop.getCropName().getCropType() != null
                        ? crop.getCropName().getCropType().getId()
                        : null)
                .cropTypeName(crop.getCropName() != null && crop.getCropName().getCropType() != null
                        ? crop.getCropName().getCropType().getDisplayName()
                        : null)
                .cropNameId(crop.getCropName() != null ? crop.getCropName().getId() : null)
                .cropName(crop.getCropName() != null ? crop.getCropName().getDisplayName() : null)
                .cropDisplayName(crop.getCropName() != null ? crop.getCropName().getDisplayName() : null)
                .areaAcres(crop.getAreaAcres())
                .sowingDate(crop.getSowingDate())
                .harvestingDate(crop.getHarvestingDate())
                .cropStatus(crop.getCropStatus() != null ? crop.getCropStatus().name() : null)
                .isActive(crop.getIsActive())
                .createdAt(crop.getCreatedAt())
                .build();
    }

    // ==================== Service Calls ====================

    private Map<String, Object> fetchKycStatus(Long userId) {
        try {
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(kycServiceUrl + "/kyc/status")
                    .header("X-User-Id", String.valueOf(userId))
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .onErrorReturn(Map.of())
                    .block();
            
            return unwrapData(response);
        } catch (Exception e) {
            log.warn("Failed to fetch KYC status for user {}: {}", userId, e.getMessage());
            return Map.of();
        }
    }
    
    private Map<String, Object> fetchSubscriptionStatus(Long userId) {
        try {
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(subscriptionServiceUrl + "/subscription/status")
                    .header("X-User-Id", String.valueOf(userId))
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .onErrorReturn(Map.of())
                    .block();
            
            return unwrapData(response);
        } catch (Exception e) {
            log.warn("Failed to fetch subscription status for user {}: {}", userId, e.getMessage());
            return Map.of();
        }
    }
    
    private Map<String, Object> fetchUserDetails(Long userId) {
        try {
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(authServiceUrl + "/auth/user/" + userId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .onErrorReturn(Map.of())
                    .block();
            
            return unwrapData(response);
        } catch (Exception e) {
            log.warn("Failed to fetch user details for user {}: {}", userId, e.getMessage());
            return Map.of();
        }
    }

    private Map<Long, Map<String, Object>> fetchKycStatusBatch(List<Long> userIds) {
        // For now, fetch individually - can be optimized with batch endpoint later
        return userIds.stream()
                .collect(Collectors.toMap(
                        userId -> userId,
                        this::fetchKycStatus,
                        (a, b) -> a
                ));
    }

    private Map<Long, Map<String, Object>> fetchSubscriptionStatusBatch(List<Long> userIds) {
        // For now, fetch individually - can be optimized with batch endpoint later
        return userIds.stream()
                .collect(Collectors.toMap(
                        userId -> userId,
                        this::fetchSubscriptionStatus,
                        (a, b) -> a
                ));
    }

    private Map<Long, Map<String, Object>> fetchUserDetailsBatch(List<Long> userIds) {
        // For now, fetch individually - can be optimized with batch endpoint later
        return userIds.stream()
                .collect(Collectors.toMap(
                        userId -> userId,
                        this::fetchUserDetails,
                        (a, b) -> a
                ));
    }

    /**
     * Fetch assignment summaries for multiple farmers from field-officer-service
     */
    private Map<Long, AssignmentSummary> fetchAssignmentSummariesBatch(List<Long> userIds) {
        return userIds.stream()
                .collect(Collectors.toMap(
                        userId -> userId,
                        this::fetchAssignmentSummary,
                        (a, b) -> a
                ));
    }

    /**
     * Fetch assignment summary for a single farmer
     */
    private AssignmentSummary fetchAssignmentSummary(Long farmerUserId) {
        try {
            String url = fieldOfficerServiceUrl + "/admin/field-officers/assignments?farmerUserId=" + farmerUserId;
            log.debug("Fetching assignments for farmer userId: {} from {}", farmerUserId, url);
            
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(url)
                    .header("X-User-Id", "1") // System admin user ID for inter-service calls
                    .header("X-User-Roles", "ADMIN")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            if (response == null) {
                log.warn("No response from field-officer-service for farmer userId: {}", farmerUserId);
                return AssignmentSummary.empty(0);
            }
            
            Object data = response.get("data");
            if (data == null) {
                log.warn("No data in response from field-officer-service for farmer userId: {}", farmerUserId);
                return AssignmentSummary.empty(0);
            }
            
            List<Map<String, Object>> assignments;
            if (data instanceof List) {
                assignments = (List<Map<String, Object>>) data;
            } else {
                log.warn("Unexpected data type in assignment response for farmer userId: {}", farmerUserId);
                return AssignmentSummary.empty(0);
            }
            
            // Count assigned farms (assignments with farmId and status != CANCELLED)
            long assignedFarmsCount = assignments.stream()
                    .filter(assignment -> {
                        Object farmId = assignment.get("farmId");
                        Object status = assignment.get("status");
                        return farmId != null && 
                               !"CANCELLED".equalsIgnoreCase(String.valueOf(status));
                    })
                    .count();
            
            // Get total farms count from farm repository
            Optional<Farmer> farmerOpt = farmerRepository.findByUserId(farmerUserId);
            int totalFarmsCount = 0;
            if (farmerOpt.isPresent()) {
                totalFarmsCount = (int) farmRepository.countByFarmerId(farmerOpt.get().getId());
            }
            
            boolean hasAllFarmsAssigned = totalFarmsCount > 0 && assignedFarmsCount == totalFarmsCount;
            boolean hasPartialAssignment = assignedFarmsCount > 0 && assignedFarmsCount < totalFarmsCount;
            
            return new AssignmentSummary(
                    (int) assignedFarmsCount,
                    totalFarmsCount,
                    hasAllFarmsAssigned,
                    hasPartialAssignment
            );
            
        } catch (Exception e) {
            log.warn("Failed to fetch assignment summary for farmer userId {}: {}", farmerUserId, e.getMessage());
            return AssignmentSummary.empty(0);
        }
    }

    /**
     * Helper class to hold assignment summary data
     */
    private static class AssignmentSummary {
        final int assignedFarmsCount;
        final int totalFarmsCount;
        final boolean hasAllFarmsAssigned;
        final boolean hasPartialAssignment;

        AssignmentSummary(int assignedFarmsCount, int totalFarmsCount, 
                          boolean hasAllFarmsAssigned, boolean hasPartialAssignment) {
            this.assignedFarmsCount = assignedFarmsCount;
            this.totalFarmsCount = totalFarmsCount;
            this.hasAllFarmsAssigned = hasAllFarmsAssigned;
            this.hasPartialAssignment = hasPartialAssignment;
        }

        static AssignmentSummary empty(int totalFarmsCount) {
            return new AssignmentSummary(0, totalFarmsCount, false, false);
        }
    }

    /**
     * Helper to unwrap our common ApiResponse<T> structure.
     * If the map contains a "data" key with a nested map, returns that,
     * otherwise returns the original map (so it also works with plain maps).
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> unwrapData(Map<String, Object> response) {
        if (response == null || response.isEmpty()) {
            return Map.of();
        }
        
        Object data = response.get("data");
        if (data instanceof Map) {
            return (Map<String, Object>) data;
        }
        
        return response;
    }
}

