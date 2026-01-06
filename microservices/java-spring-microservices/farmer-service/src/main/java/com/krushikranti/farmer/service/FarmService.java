package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.FarmRequest;
import com.krushikranti.farmer.dto.FarmResponse;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.FarmerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing farm details.
 * Handles CRUD operations and business logic for farms.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmService {

    private final FarmRepository farmRepository;
    private final FarmerRepository farmerRepository;
    private final PincodeService pincodeService;

    /**
     * Get all active farms for a farmer.
     */
    @Transactional(readOnly = true)
    public List<FarmResponse> getFarmsByUserId(Long userId) {
        Farmer farmer = getFarmerByUserId(userId);
        List<Farm> farms = farmRepository.findByFarmerIdAndIsActiveTrue(farmer.getId());
        
        log.debug("Found {} active farms for userId: {}", farms.size(), userId);
        return farms.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get a specific farm by ID for a farmer.
     */
    @Transactional(readOnly = true)
    public FarmResponse getFarmById(Long userId, Long farmId) {
        Farmer farmer = getFarmerByUserId(userId);
        Farm farm = farmRepository.findByIdAndFarmerIdAndIsActiveTrue(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException("Farm not found with ID: " + farmId));
        
        log.debug("Retrieved farm {} for userId: {}", farmId, userId);
        return mapToResponse(farm);
    }

    /**
     * Create a new farm for a farmer.
     */
    @Transactional
    public FarmResponse createFarm(Long userId, FarmRequest request) {
        Farmer farmer = getFarmerByUserId(userId);
        
        // Validate farm name uniqueness
        if (farmRepository.existsByFarmerIdAndFarmNameIgnoreCase(farmer.getId(), request.getFarmName())) {
            throw new IllegalArgumentException("A farm with this name already exists");
        }
        
        // Validate and fetch address from pincode
        AddressLookupResponse address = pincodeService.getAddressByPincode(request.getPincode());
        
        // Validate village is in the pincode
        if (!address.getVillages().stream().anyMatch(v -> v.equalsIgnoreCase(request.getVillage()))) {
            throw new IllegalArgumentException("Village '" + request.getVillage() + "' is not valid for pincode: " + request.getPincode());
        }
        
        Farm farm = Farm.builder()
                .farmer(farmer)
                .farmName(request.getFarmName())
                .farmType(request.getFarmType())
                .totalAreaAcres(request.getTotalAreaAcres())
                .pincode(request.getPincode())
                .village(request.getVillage())
                .district(address.getDistrict())
                .taluka(address.getTaluka())
                .state(address.getState())
                .soilType(request.getSoilType())
                .irrigationType(request.getIrrigationType())
                .landOwnership(request.getLandOwnership())
                .surveyNumber(request.getSurveyNumber())
                .landRegistrationNumber(request.getLandRegistrationNumber())
                .pattaNumber(request.getPattaNumber())
                .estimatedLandValue(request.getEstimatedLandValue())
                .encumbranceStatus(request.getEncumbranceStatus() != null 
                        ? request.getEncumbranceStatus() 
                        : Farm.EncumbranceStatus.NOT_VERIFIED)
                .encumbranceRemarks(request.getEncumbranceRemarks())
                .landDocumentUrl(request.getLandDocumentUrl())
                .surveyMapUrl(request.getSurveyMapUrl())
                .registrationCertificateUrl(request.getRegistrationCertificateUrl())
                // GPS coordinates (optional)
                .farmLatitude(request.getFarmLatitude())
                .farmLongitude(request.getFarmLongitude())
                .farmLocationAccuracy(request.getFarmLocationAccuracy() != null 
                        ? request.getFarmLocationAccuracy().setScale(2, RoundingMode.HALF_UP)
                        : null)
                .farmLocationCapturedAt(request.getFarmLatitude() != null && request.getFarmLongitude() != null 
                        ? LocalDateTime.now() 
                        : null)
                .isVerified(false)
                .isActive(true)
                .build();
        
        Farm savedFarm = farmRepository.save(farm);
        log.info("Created farm {} for userId: {}", savedFarm.getId(), userId);
        
        return mapToResponse(savedFarm);
    }

    /**
     * Update an existing farm.
     */
    @Transactional
    public FarmResponse updateFarm(Long userId, Long farmId, FarmRequest request) {
        Farmer farmer = getFarmerByUserId(userId);
        Farm farm = farmRepository.findByIdAndFarmerIdAndIsActiveTrue(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException("Farm not found with ID: " + farmId));
        
        // Validate farm name uniqueness (excluding current farm)
        if (farmRepository.existsByFarmerIdAndFarmNameIgnoreCaseExcludingId(
                farmer.getId(), request.getFarmName(), farmId)) {
            throw new IllegalArgumentException("A farm with this name already exists");
        }
        
        // Validate and fetch address from pincode
        AddressLookupResponse address = pincodeService.getAddressByPincode(request.getPincode());
        
        // Validate village is in the pincode
        if (!address.getVillages().stream().anyMatch(v -> v.equalsIgnoreCase(request.getVillage()))) {
            throw new IllegalArgumentException("Village '" + request.getVillage() + "' is not valid for pincode: " + request.getPincode());
        }
        
        // Update basic info
        farm.setFarmName(request.getFarmName());
        farm.setFarmType(request.getFarmType());
        farm.setTotalAreaAcres(request.getTotalAreaAcres());
        farm.setPincode(request.getPincode());
        farm.setVillage(request.getVillage());
        farm.setDistrict(address.getDistrict());
        farm.setTaluka(address.getTaluka());
        farm.setState(address.getState());
        farm.setSoilType(request.getSoilType());
        farm.setIrrigationType(request.getIrrigationType());
        farm.setLandOwnership(request.getLandOwnership());
        
        // Update collateral info
        farm.setSurveyNumber(request.getSurveyNumber());
        farm.setLandRegistrationNumber(request.getLandRegistrationNumber());
        farm.setPattaNumber(request.getPattaNumber());
        farm.setEstimatedLandValue(request.getEstimatedLandValue());
        if (request.getEncumbranceStatus() != null) {
            farm.setEncumbranceStatus(request.getEncumbranceStatus());
        }
        farm.setEncumbranceRemarks(request.getEncumbranceRemarks());
        
        // Update document URLs
        farm.setLandDocumentUrl(request.getLandDocumentUrl());
        farm.setSurveyMapUrl(request.getSurveyMapUrl());
        farm.setRegistrationCertificateUrl(request.getRegistrationCertificateUrl());
        
        // Update GPS coordinates (if provided)
        farm.setFarmLatitude(request.getFarmLatitude());
        farm.setFarmLongitude(request.getFarmLongitude());
        // Round accuracy to 2 decimal places for consistency
        farm.setFarmLocationAccuracy(request.getFarmLocationAccuracy() != null 
                ? request.getFarmLocationAccuracy().setScale(2, RoundingMode.HALF_UP)
                : null);
        // Update captured timestamp if GPS coordinates are being set/updated
        if (request.getFarmLatitude() != null && request.getFarmLongitude() != null) {
            farm.setFarmLocationCapturedAt(LocalDateTime.now());
        }
        
        // Note: Verification status is not updated by farmer
        // If farm details change significantly, admin may need to re-verify
        if (farm.getIsVerified() && hasSignificantChanges(farm, request)) {
            log.warn("Farm {} was previously verified but details changed. May need re-verification.", farmId);
            // Optionally: Reset verification status
            // farm.setIsVerified(false);
            // farm.setVerifiedBy(null);
            // farm.setVerifiedAt(null);
        }
        
        Farm updatedFarm = farmRepository.save(farm);
        log.info("Updated farm {} for userId: {}", farmId, userId);
        
        return mapToResponse(updatedFarm);
    }

    /**
     * Soft delete a farm.
     */
    @Transactional
    public void deleteFarm(Long userId, Long farmId) {
        Farmer farmer = getFarmerByUserId(userId);
        Farm farm = farmRepository.findByIdAndFarmerIdAndIsActiveTrue(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException("Farm not found with ID: " + farmId));
        
        farm.setIsActive(false);
        farmRepository.save(farm);
        
        log.info("Soft deleted farm {} for userId: {}", farmId, userId);
    }

    /**
     * Get count of active farms for a farmer.
     */
    @Transactional(readOnly = true)
    public long getFarmCount(Long userId) {
        Farmer farmer = getFarmerByUserId(userId);
        return farmRepository.countByFarmerIdAndIsActiveTrue(farmer.getId());
    }

    /**
     * Get all farms that are valid for loan collateral.
     */
    @Transactional(readOnly = true)
    public List<FarmResponse> getValidCollateralFarms(Long userId) {
        Farmer farmer = getFarmerByUserId(userId);
        List<Farm> farms = farmRepository.findValidCollateralFarms(farmer.getId());
        
        log.debug("Found {} valid collateral farms for userId: {}", farms.size(), userId);
        return farms.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    // ========================================
    // HELPER METHODS
    // ========================================
    
    private Farmer getFarmerByUserId(Long userId) {
        return farmerRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Farmer profile not found. Please complete your profile first."));
    }

    private boolean hasSignificantChanges(Farm farm, FarmRequest request) {
        // Check if significant details have changed that might require re-verification
        return !farm.getTotalAreaAcres().equals(request.getTotalAreaAcres())
                || !farm.getLandOwnership().equals(request.getLandOwnership())
                || !farm.getPincode().equals(request.getPincode())
                || (request.getSurveyNumber() != null && !request.getSurveyNumber().equals(farm.getSurveyNumber()));
    }

    private FarmResponse mapToResponse(Farm farm) {
        return FarmResponse.builder()
                .id(farm.getId())
                .farmerId(farm.getFarmer().getId())
                .farmName(farm.getFarmName())
                .farmType(farm.getFarmType())
                .totalAreaAcres(farm.getTotalAreaAcres())
                .pincode(farm.getPincode())
                .village(farm.getVillage())
                .district(farm.getDistrict())
                .taluka(farm.getTaluka())
                .state(farm.getState())
                .soilType(farm.getSoilType())
                .irrigationType(farm.getIrrigationType())
                .landOwnership(farm.getLandOwnership())
                .surveyNumber(farm.getSurveyNumber())
                .landRegistrationNumber(farm.getLandRegistrationNumber())
                .pattaNumber(farm.getPattaNumber())
                .estimatedLandValue(farm.getEstimatedLandValue())
                .encumbranceStatus(farm.getEncumbranceStatus())
                .encumbranceRemarks(farm.getEncumbranceRemarks())
                .landDocumentUrl(farm.getLandDocumentUrl())
                .surveyMapUrl(farm.getSurveyMapUrl())
                .registrationCertificateUrl(farm.getRegistrationCertificateUrl())
                .isVerified(farm.getIsVerified())
                .verifiedBy(farm.getVerifiedBy())
                .verifiedAt(farm.getVerifiedAt())
                .verificationRemarks(farm.getVerificationRemarks())
                // GPS coordinates
                .farmLatitude(farm.getFarmLatitude())
                .farmLongitude(farm.getFarmLongitude())
                .farmLocationAccuracy(farm.getFarmLocationAccuracy())
                .farmLocationCapturedAt(farm.getFarmLocationCapturedAt())
                .isActive(farm.getIsActive())
                .createdAt(farm.getCreatedAt())
                .updatedAt(farm.getUpdatedAt())
                .build();
    }
}

