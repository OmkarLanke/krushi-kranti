package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.CropTypeRequest;
import com.krushikranti.farmer.dto.CropTypeResponse;
import com.krushikranti.farmer.model.CropType;
import com.krushikranti.farmer.repository.CropNameRepository;
import com.krushikranti.farmer.repository.CropTypeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service for managing crop types (master data).
 * Admin operations for CRUD on crop types.
 *
 * Caching: Uses Redis cache "cropTypes" for getActiveCropTypes.
 * Cache is evicted on create, update, delete, and restore operations.
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
        return getActiveCropTypes("en");
    }

    /**
     * Get all active crop types with language support (for farmer app dropdown).
     * Cached in Redis for 1 hour.
     *
     * @param language Language code: "en", "hi", or "mr" (defaults to "en" if invalid)
     * @return List of crop types in the requested language
     */
    @Transactional(readOnly = true)
    @Cacheable(value = "cropTypes", key = "#language")
    public List<CropTypeResponse> getActiveCropTypes(String language) {
        log.debug("Cache miss for cropTypes with language: {} - fetching from database", language);

        // Normalize language code
        String normalizedLanguage = "en"; // Default
        if (language != null && !language.trim().isEmpty()) {
            String lang = language.toLowerCase().trim();
            if (lang.equals("hi") || lang.equals("mr")) {
                normalizedLanguage = lang;
            }
        }

        final String finalLanguage = normalizedLanguage;
        List<CropType> cropTypes = cropTypeRepository.findByIsActiveTrueOrderByDisplayOrderAsc();

        // Batch load all crop name counts to avoid N+1 queries
        Map<Long, Long> cropNameCounts = getCropNameCountsMap();

        return cropTypes.stream()
                .map(cropType -> mapToResponse(cropType, finalLanguage, cropNameCounts.getOrDefault(cropType.getId(), 0L)))
                .collect(Collectors.toList());
    }

    /**
     * Get all crop types including inactive (for admin).
     */
    @Transactional(readOnly = true)
    public List<CropTypeResponse> getAllCropTypes() {
        List<CropType> cropTypes = cropTypeRepository.findAllByOrderByDisplayOrderAsc();

        // Batch load all crop name counts to avoid N+1 queries
        Map<Long, Long> cropNameCounts = getCropNameCountsMap();

        return cropTypes.stream()
                .map(cropType -> mapToResponse(cropType, "en", cropNameCounts.getOrDefault(cropType.getId(), 0L)))
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
    @CacheEvict(value = "cropTypes", allEntries = true)
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
    @CacheEvict(value = "cropTypes", allEntries = true)
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
    @CacheEvict(value = "cropTypes", allEntries = true)
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
    @CacheEvict(value = "cropTypes", allEntries = true)
    public CropTypeResponse restoreCropType(Long id) {
        CropType cropType = cropTypeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Crop type not found with ID: " + id));

        cropType.setIsActive(true);
        CropType restoredCropType = cropTypeRepository.save(cropType);
        log.info("Restored crop type: {}", restoredCropType.getTypeName());

        return mapToResponse(restoredCropType);
    }

    private CropTypeResponse mapToResponse(CropType cropType) {
        return mapToResponse(cropType, "en", cropNameRepository.countByCropTypeIdAndIsActiveTrue(cropType.getId()));
    }

    private CropTypeResponse mapToResponse(CropType cropType, String language) {
        return mapToResponse(cropType, language, cropNameRepository.countByCropTypeIdAndIsActiveTrue(cropType.getId()));
    }

    private CropTypeResponse mapToResponse(CropType cropType, String language, long cropNameCount) {
        // Select display name based on language
        String displayNameToUse = cropType.getDisplayName(); // Default to English
        if ("hi".equals(language) && cropType.getDisplayNameHi() != null && !cropType.getDisplayNameHi().trim().isEmpty()) {
            displayNameToUse = cropType.getDisplayNameHi();
        } else if ("mr".equals(language) && cropType.getDisplayNameMr() != null && !cropType.getDisplayNameMr().trim().isEmpty()) {
            displayNameToUse = cropType.getDisplayNameMr();
        }

        return CropTypeResponse.builder()
                .id(cropType.getId())
                .typeName(cropType.getTypeName())
                .displayName(displayNameToUse)
                .description(cropType.getDescription())
                .iconUrl(cropType.getIconUrl())
                .displayOrder(cropType.getDisplayOrder())
                .isActive(cropType.getIsActive())
                .cropNameCount(cropNameCount)
                .createdAt(cropType.getCreatedAt())
                .updatedAt(cropType.getUpdatedAt())
                .build();
    }

    /**
     * Get crop name counts for all crop types as a map (cropTypeId -> count).
     */
    private Map<Long, Long> getCropNameCountsMap() {
        List<Object[]> counts = cropNameRepository.countByCropTypeGrouped();
        Map<Long, Long> countsMap = new HashMap<>();
        for (Object[] row : counts) {
            countsMap.put((Long) row[0], (Long) row[1]);
        }
        return countsMap;
    }
}

