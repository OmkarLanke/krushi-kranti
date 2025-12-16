package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.CropRequest;
import com.krushikranti.farmer.dto.CropResponse;
import com.krushikranti.farmer.model.Crop;
import com.krushikranti.farmer.model.CropName;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.CropNameRepository;
import com.krushikranti.farmer.repository.CropRepository;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.FarmerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing farmer's crops.
 * Handles CRUD operations for crops on farms.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CropService {

    private final CropRepository cropRepository;
    private final FarmRepository farmRepository;
    private final FarmerRepository farmerRepository;
    private final CropNameRepository cropNameRepository;

    /**
     * Get all crops for a specific farm.
     */
    @Transactional(readOnly = true)
    public List<CropResponse> getCropsByFarmId(Long userId, Long farmId) {
        Farm farm = getFarmByUserIdAndFarmId(userId, farmId);
        List<Crop> crops = cropRepository.findByFarmIdAndIsActiveTrue(farm.getId());
        
        log.debug("Found {} active crops for farmId: {}", crops.size(), farmId);
        return crops.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all crops for a farmer (across all farms).
     */
    @Transactional(readOnly = true)
    public List<CropResponse> getAllCropsByUserId(Long userId) {
        // Verify farmer exists
        getFarmerByUserId(userId);
        
        List<Crop> crops = cropRepository.findByFarmerUserIdWithDetails(userId);
        log.debug("Found {} active crops for userId: {}", crops.size(), userId);
        
        return crops.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get a specific crop by ID.
     */
    @Transactional(readOnly = true)
    public CropResponse getCropById(Long userId, Long cropId) {
        Crop crop = getCropByUserIdAndCropId(userId, cropId);
        return mapToResponse(crop);
    }

    /**
     * Create a new crop on a farm.
     */
    @Transactional
    public CropResponse createCrop(Long userId, CropRequest request) {
        Farm farm = getFarmByUserIdAndFarmId(userId, request.getFarmId());
        
        // Validate crop name exists and is active
        CropName cropName = cropNameRepository.findByIdAndIsActiveTrue(request.getCropNameId())
                .orElseThrow(() -> new IllegalArgumentException("Crop name not found or inactive with ID: " + request.getCropNameId()));
        
        // Check if this crop already exists on this farm
        if (cropRepository.existsByFarmIdAndCropNameIdAndIsActiveTrue(farm.getId(), cropName.getId())) {
            throw new IllegalArgumentException("This crop already exists on this farm. Please update the existing crop instead.");
        }
        
        // Validate total crop area doesn't exceed farm area
        validateCropArea(farm, request.getAreaAcres(), null);
        
        Crop crop = Crop.builder()
                .farm(farm)
                .cropName(cropName)
                .areaAcres(request.getAreaAcres())
                .sowingDate(request.getSowingDate())
                .harvestingDate(request.getHarvestingDate())
                .cropStatus(request.getCropStatus() != null 
                        ? request.getCropStatus() 
                        : Crop.CropStatus.PLANNED)
                .isActive(true)
                .build();
        
        Crop savedCrop = cropRepository.save(crop);
        log.info("Created crop {} on farmId: {} for userId: {}", cropName.getDisplayName(), farm.getId(), userId);
        
        return mapToResponse(savedCrop);
    }

    /**
     * Update an existing crop.
     */
    @Transactional
    public CropResponse updateCrop(Long userId, Long cropId, CropRequest request) {
        Crop crop = getCropByUserIdAndCropId(userId, cropId);
        Farm farm = crop.getFarm();
        
        // Validate farm ID matches
        if (!farm.getId().equals(request.getFarmId())) {
            throw new IllegalArgumentException("Cannot change farm for an existing crop. Delete and recreate instead.");
        }
        
        // Validate crop name if changed
        if (!crop.getCropName().getId().equals(request.getCropNameId())) {
            CropName newCropName = cropNameRepository.findByIdAndIsActiveTrue(request.getCropNameId())
                    .orElseThrow(() -> new IllegalArgumentException("Crop name not found or inactive with ID: " + request.getCropNameId()));
            
            // Check if the new crop already exists on this farm
            if (cropRepository.existsByFarmIdAndCropNameIdAndIsActiveTrue(farm.getId(), newCropName.getId())) {
                throw new IllegalArgumentException("This crop already exists on this farm.");
            }
            
            crop.setCropName(newCropName);
        }
        
        // Validate total crop area doesn't exceed farm area
        validateCropArea(farm, request.getAreaAcres(), cropId);
        
        crop.setAreaAcres(request.getAreaAcres());
        crop.setSowingDate(request.getSowingDate());
        crop.setHarvestingDate(request.getHarvestingDate());
        if (request.getCropStatus() != null) {
            crop.setCropStatus(request.getCropStatus());
        }
        
        Crop updatedCrop = cropRepository.save(crop);
        log.info("Updated crop {} for userId: {}", cropId, userId);
        
        return mapToResponse(updatedCrop);
    }

    /**
     * Delete a crop (soft delete).
     */
    @Transactional
    public void deleteCrop(Long userId, Long cropId) {
        Crop crop = getCropByUserIdAndCropId(userId, cropId);
        crop.setIsActive(false);
        cropRepository.save(crop);
        
        log.info("Soft deleted crop {} for userId: {}", cropId, userId);
    }

    /**
     * Get crop count for a farm.
     */
    @Transactional(readOnly = true)
    public long getCropCount(Long userId, Long farmId) {
        Farm farm = getFarmByUserIdAndFarmId(userId, farmId);
        return cropRepository.countByFarmIdAndIsActiveTrue(farm.getId());
    }

    /**
     * Get crops by crop type for a farmer.
     */
    @Transactional(readOnly = true)
    public List<CropResponse> getCropsByType(Long userId, Long cropTypeId) {
        getFarmerByUserId(userId);
        
        List<Crop> crops = cropRepository.findByFarmerUserIdAndCropTypeId(userId, cropTypeId);
        return crops.stream()
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

    private Farm getFarmByUserIdAndFarmId(Long userId, Long farmId) {
        Farmer farmer = getFarmerByUserId(userId);
        return farmRepository.findByIdAndFarmerIdAndIsActiveTrue(farmId, farmer.getId())
                .orElseThrow(() -> new IllegalArgumentException("Farm not found with ID: " + farmId));
    }

    private Crop getCropByUserIdAndCropId(Long userId, Long cropId) {
        getFarmerByUserId(userId);
        
        return cropRepository.findByFarmerUserId(userId).stream()
                .filter(crop -> crop.getId().equals(cropId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Crop not found with ID: " + cropId));
    }

    private void validateCropArea(Farm farm, BigDecimal newCropArea, Long excludeCropId) {
        // Get total area of all active crops for this farm (excluding current crop if updating)
        BigDecimal totalCropArea = cropRepository.findByFarmIdAndIsActiveTrue(farm.getId()).stream()
                .filter(crop -> excludeCropId == null || !crop.getId().equals(excludeCropId))
                .map(Crop::getAreaAcres)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal newTotalArea = totalCropArea.add(newCropArea);
        if (newTotalArea.compareTo(farm.getTotalAreaAcres()) > 0) {
            throw new IllegalArgumentException(
                    String.format("Total crop area (%.2f acres) cannot exceed farm area (%.2f acres). Available area: %.2f acres",
                            newTotalArea, farm.getTotalAreaAcres(), 
                            farm.getTotalAreaAcres().subtract(totalCropArea)));
        }
    }

    private CropResponse mapToResponse(Crop crop) {
        CropName cropName = crop.getCropName();
        Farm farm = crop.getFarm();
        
        return CropResponse.builder()
                .id(crop.getId())
                .farmId(farm.getId())
                .farmName(farm.getFarmName())
                .cropTypeId(cropName.getCropType().getId())
                .cropTypeName(cropName.getCropType().getTypeName())
                .cropTypeDisplayName(cropName.getCropType().getDisplayName())
                .cropNameId(cropName.getId())
                .cropName(cropName.getName())
                .cropDisplayName(cropName.getDisplayName())
                .cropLocalName(cropName.getLocalName())
                .areaAcres(crop.getAreaAcres())
                .sowingDate(crop.getSowingDate())
                .harvestingDate(crop.getHarvestingDate())
                .cropStatus(crop.getCropStatus())
                .isActive(crop.getIsActive())
                .createdAt(crop.getCreatedAt())
                .updatedAt(crop.getUpdatedAt())
                .build();
    }
}

