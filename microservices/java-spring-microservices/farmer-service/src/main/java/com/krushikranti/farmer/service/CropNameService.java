package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.CropNameRequest;
import com.krushikranti.farmer.dto.CropNameResponse;
import com.krushikranti.farmer.model.CropName;
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
 * Service for managing crop names (master data).
 * Admin operations for CRUD on crop names.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CropNameService {

    private final CropNameRepository cropNameRepository;
    private final CropTypeRepository cropTypeRepository;

    /**
     * Get active crop names by crop type ID (for farmer app dropdown).
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> getActiveCropNamesByTypeId(Long cropTypeId) {
        return getActiveCropNamesByTypeId(cropTypeId, "en");
    }

    /**
     * Get active crop names by crop type ID with language support (for farmer app dropdown).
     * 
     * @param cropTypeId The crop type ID
     * @param language Language code: "en", "hi", or "mr" (defaults to "en" if invalid)
     * @return List of crop names in the requested language
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> getActiveCropNamesByTypeId(Long cropTypeId, String language) {
        // Validate crop type exists and is active
        CropType cropType = cropTypeRepository.findById(cropTypeId)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + cropTypeId));
        
        if (!cropType.getIsActive()) {
            throw new IllegalArgumentException("Crop type is not active");
        }

        // Normalize language code
        String normalizedLanguage = "en"; // Default
        if (language != null && !language.trim().isEmpty()) {
            String lang = language.toLowerCase().trim();
            if (lang.equals("hi") || lang.equals("mr")) {
                normalizedLanguage = lang;
            }
        }

        final String finalLanguage = normalizedLanguage;
        List<CropName> cropNames = cropNameRepository.findByCropTypeIdAndIsActiveTrueOrderByDisplayOrderAsc(cropTypeId);
        return cropNames.stream()
                .map(cropName -> mapToResponse(cropName, finalLanguage))
                .collect(Collectors.toList());
    }

    /**
     * Get all crop names by crop type ID (for admin).
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> getAllCropNamesByTypeId(Long cropTypeId) {
        List<CropName> cropNames = cropNameRepository.findByCropTypeIdOrderByDisplayOrderAsc(cropTypeId);
        return cropNames.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all active crop names (for admin listing all).
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> getAllActiveCropNames() {
        List<CropName> cropNames = cropNameRepository.findAllActiveOrderedByTypeAndName();
        return cropNames.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get crop name by ID.
     */
    @Transactional(readOnly = true)
    public CropNameResponse getCropNameById(Long id) {
        CropName cropName = cropNameRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop name not found with ID: " + id));
        return mapToResponse(cropName);
    }

    /**
     * Search crop names by term.
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> searchCropNames(String searchTerm) {
        return searchCropNames(searchTerm, "en");
    }

    /**
     * Search crop names by term with language support.
     * 
     * @param searchTerm The search term
     * @param language Language code: "en", "hi", or "mr" (defaults to "en" if invalid)
     * @return List of matching crop names in the requested language
     */
    @Transactional(readOnly = true)
    public List<CropNameResponse> searchCropNames(String searchTerm, String language) {
        // Normalize language code
        String normalizedLanguage = "en"; // Default
        if (language != null && !language.trim().isEmpty()) {
            String lang = language.toLowerCase().trim();
            if (lang.equals("hi") || lang.equals("mr")) {
                normalizedLanguage = lang;
            }
        }

        final String finalLanguage = normalizedLanguage;
        List<CropName> cropNames = cropNameRepository.searchByNameContaining(searchTerm);
        return cropNames.stream()
                .map(cropName -> mapToResponse(cropName, finalLanguage))
                .collect(Collectors.toList());
    }

    /**
     * Create a new crop name (admin only).
     */
    @Transactional
    public CropNameResponse createCropName(CropNameRequest request) {
        // Validate crop type exists
        CropType cropType = cropTypeRepository.findById(request.getCropTypeId())
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + request.getCropTypeId()));

        // Validate unique name per crop type
        if (cropNameRepository.existsByNameIgnoreCaseAndCropTypeId(request.getName(), request.getCropTypeId())) {
            throw new IllegalArgumentException("Crop name '" + request.getName() + "' already exists for this crop type");
        }

        CropName cropName = CropName.builder()
                .cropType(cropType)
                .name(request.getName().toUpperCase().replace(" ", "_"))
                .displayName(request.getDisplayName())
                .localName(request.getLocalName())
                .description(request.getDescription())
                .iconUrl(request.getIconUrl())
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();

        CropName savedCropName = cropNameRepository.save(cropName);
        log.info("Created crop name: {} under type: {}", savedCropName.getName(), cropType.getTypeName());

        return mapToResponse(savedCropName);
    }

    /**
     * Update an existing crop name (admin only).
     */
    @Transactional
    public CropNameResponse updateCropName(Long id, CropNameRequest request) {
        CropName cropName = cropNameRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop name not found with ID: " + id));

        // Validate crop type exists
        CropType cropType = cropTypeRepository.findById(request.getCropTypeId())
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + request.getCropTypeId()));

        // Validate unique name per crop type (excluding current)
        if (cropNameRepository.existsByNameIgnoreCaseAndCropTypeIdAndIdNot(
                request.getName(), request.getCropTypeId(), id)) {
            throw new IllegalArgumentException("Crop name '" + request.getName() + "' already exists for this crop type");
        }

        cropName.setCropType(cropType);
        cropName.setName(request.getName().toUpperCase().replace(" ", "_"));
        cropName.setDisplayName(request.getDisplayName());
        cropName.setLocalName(request.getLocalName());
        cropName.setDescription(request.getDescription());
        cropName.setIconUrl(request.getIconUrl());
        if (request.getDisplayOrder() != null) {
            cropName.setDisplayOrder(request.getDisplayOrder());
        }
        if (request.getIsActive() != null) {
            cropName.setIsActive(request.getIsActive());
        }

        CropName updatedCropName = cropNameRepository.save(cropName);
        log.info("Updated crop name: {}", updatedCropName.getName());

        return mapToResponse(updatedCropName);
    }

    /**
     * Soft delete a crop name (admin only).
     */
    @Transactional
    public void deleteCropName(Long id) {
        CropName cropName = cropNameRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop name not found with ID: " + id));

        cropName.setIsActive(false);
        cropNameRepository.save(cropName);
        log.info("Soft deleted crop name: {}", cropName.getName());
    }

    /**
     * Restore a deleted crop name (admin only).
     */
    @Transactional
    public CropNameResponse restoreCropName(Long id) {
        CropName cropName = cropNameRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop name not found with ID: " + id));

        cropName.setIsActive(true);
        CropName restoredCropName = cropNameRepository.save(cropName);
        log.info("Restored crop name: {}", restoredCropName.getName());

        return mapToResponse(restoredCropName);
    }

    private CropNameResponse mapToResponse(CropName cropName) {
        return mapToResponse(cropName, "en");
    }

    private CropNameResponse mapToResponse(CropName cropName, String language) {
        // Determine display name based on language
        String displayNameToUse = cropName.getDisplayName(); // Default to English
        if (("hi".equals(language) || "mr".equals(language)) && cropName.getLocalName() != null && !cropName.getLocalName().trim().isEmpty()) {
            displayNameToUse = cropName.getLocalName();
        }

        return CropNameResponse.builder()
                .id(cropName.getId())
                .cropTypeId(cropName.getCropType().getId())
                .cropTypeName(cropName.getCropType().getTypeName())
                .cropTypeDisplayName(cropName.getCropType().getDisplayName())
                .name(cropName.getName())
                .displayName(displayNameToUse) // Use translated name
                .localName(cropName.getLocalName())
                .description(cropName.getDescription())
                .iconUrl(cropName.getIconUrl())
                .displayOrder(cropName.getDisplayOrder())
                .isActive(cropName.getIsActive())
                .createdAt(cropName.getCreatedAt())
                .updatedAt(cropName.getUpdatedAt())
                .build();
    }
}

