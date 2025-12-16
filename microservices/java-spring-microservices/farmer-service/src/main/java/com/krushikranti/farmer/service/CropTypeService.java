package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.CropTypeRequest;
import com.krushikranti.farmer.dto.CropTypeResponse;
import com.krushikranti.farmer.model.CropType;
import com.krushikranti.farmer.repository.CropNameRepository;
import com.krushikranti.farmer.repository.CropTypeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing crop types (master data).
 * Admin operations for CRUD on crop types.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CropTypeService {

    private final CropTypeRepository cropTypeRepository;
    private final CropNameRepository cropNameRepository;

    /**
     * Get all active crop types (for farmer app dropdown).
     */
    @Transactional(readOnly = true)
    public List<CropTypeResponse> getActiveCropTypes() {
        List<CropType> cropTypes = cropTypeRepository.findByIsActiveTrueOrderByDisplayOrderAsc();
        return cropTypes.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all crop types including inactive (for admin).
     */
    @Transactional(readOnly = true)
    public List<CropTypeResponse> getAllCropTypes() {
        List<CropType> cropTypes = cropTypeRepository.findAllByOrderByDisplayOrderAsc();
        return cropTypes.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get crop type by ID.
     */
    @Transactional(readOnly = true)
    public CropTypeResponse getCropTypeById(Long id) {
        CropType cropType = cropTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + id));
        return mapToResponse(cropType);
    }

    /**
     * Create a new crop type (admin only).
     */
    @Transactional
    public CropTypeResponse createCropType(CropTypeRequest request) {
        // Validate unique type name
        if (cropTypeRepository.existsByTypeNameIgnoreCase(request.getTypeName())) {
            throw new IllegalArgumentException("Crop type with name '" + request.getTypeName() + "' already exists");
        }

        CropType cropType = CropType.builder()
                .typeName(request.getTypeName().toUpperCase().replace(" ", "_"))
                .displayName(request.getDisplayName())
                .description(request.getDescription())
                .iconUrl(request.getIconUrl())
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();

        CropType savedCropType = cropTypeRepository.save(cropType);
        log.info("Created crop type: {}", savedCropType.getTypeName());

        return mapToResponse(savedCropType);
    }

    /**
     * Update an existing crop type (admin only).
     */
    @Transactional
    public CropTypeResponse updateCropType(Long id, CropTypeRequest request) {
        CropType cropType = cropTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + id));

        // Validate unique type name (excluding current)
        if (cropTypeRepository.existsByTypeNameIgnoreCaseAndIdNot(request.getTypeName(), id)) {
            throw new IllegalArgumentException("Crop type with name '" + request.getTypeName() + "' already exists");
        }

        cropType.setTypeName(request.getTypeName().toUpperCase().replace(" ", "_"));
        cropType.setDisplayName(request.getDisplayName());
        cropType.setDescription(request.getDescription());
        cropType.setIconUrl(request.getIconUrl());
        if (request.getDisplayOrder() != null) {
            cropType.setDisplayOrder(request.getDisplayOrder());
        }
        if (request.getIsActive() != null) {
            cropType.setIsActive(request.getIsActive());
        }

        CropType updatedCropType = cropTypeRepository.save(cropType);
        log.info("Updated crop type: {}", updatedCropType.getTypeName());

        return mapToResponse(updatedCropType);
    }

    /**
     * Soft delete a crop type (admin only).
     */
    @Transactional
    public void deleteCropType(Long id) {
        CropType cropType = cropTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + id));

        cropType.setIsActive(false);
        cropTypeRepository.save(cropType);
        log.info("Soft deleted crop type: {}", cropType.getTypeName());
    }

    /**
     * Restore a deleted crop type (admin only).
     */
    @Transactional
    public CropTypeResponse restoreCropType(Long id) {
        CropType cropType = cropTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + id));

        cropType.setIsActive(true);
        CropType restoredCropType = cropTypeRepository.save(cropType);
        log.info("Restored crop type: {}", restoredCropType.getTypeName());

        return mapToResponse(restoredCropType);
    }

    private CropTypeResponse mapToResponse(CropType cropType) {
        long cropNameCount = cropNameRepository.countByCropTypeIdAndIsActiveTrue(cropType.getId());
        
        return CropTypeResponse.builder()
                .id(cropType.getId())
                .typeName(cropType.getTypeName())
                .displayName(cropType.getDisplayName())
                .description(cropType.getDescription())
                .iconUrl(cropType.getIconUrl())
                .displayOrder(cropType.getDisplayOrder())
                .isActive(cropType.getIsActive())
                .cropNameCount(cropNameCount)
                .createdAt(cropType.getCreatedAt())
                .updatedAt(cropType.getUpdatedAt())
                .build();
    }
}

