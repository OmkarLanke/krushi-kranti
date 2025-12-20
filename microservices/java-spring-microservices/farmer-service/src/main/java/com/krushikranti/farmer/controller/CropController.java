package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.CropRequest;
import com.krushikranti.farmer.dto.CropResponse;
import com.krushikranti.farmer.service.CropService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST Controller for farmer's crop management.
 * All endpoints are protected and require JWT token via API Gateway.
 */
@RestController
@RequestMapping("/farmer/profile/crops")
@RequiredArgsConstructor
@Slf4j
public class CropController {

    private final CropService cropService;

    /**
     * Get all crops for the logged-in farmer (across all farms).
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CropResponse>>> getAllCrops(
            @RequestHeader("X-User-Id") String userIdHeader,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        
        Long userId = Long.parseLong(userIdHeader);
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting all crops for userId: {} with language: {}", userId, language);
        
        List<CropResponse> crops = cropService.getAllCropsByUserId(userId, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }

    /**
     * Get all crops for a specific farm.
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/farm/{farmId}")
    public ResponseEntity<ApiResponse<List<CropResponse>>> getCropsByFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        
        Long userId = Long.parseLong(userIdHeader);
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting crops for farmId: {} userId: {} with language: {}", farmId, userId, language);
        
        List<CropResponse> crops = cropService.getCropsByFarmId(userId, farmId, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }

    /**
     * Get a specific crop by ID.
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/{cropId}")
    public ResponseEntity<ApiResponse<CropResponse>> getCropById(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropId,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        
        Long userId = Long.parseLong(userIdHeader);
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting crop {} for userId: {} with language: {}", cropId, userId, language);
        
        CropResponse crop = cropService.getCropById(userId, cropId, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop retrieved successfully",
                crop));
    }

    /**
     * Create a new crop on a farm.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<CropResponse>> createCrop(
            @RequestHeader("X-User-Id") String userIdHeader,
            @Valid @RequestBody CropRequest request) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Creating crop for userId: {} on farmId: {}", userId, request.getFarmId());
        
        CropResponse crop = cropService.createCrop(userId, request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(
                        "Crop created successfully",
                        crop));
    }

    /**
     * Update an existing crop.
     */
    @PutMapping("/{cropId}")
    public ResponseEntity<ApiResponse<CropResponse>> updateCrop(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropId,
            @Valid @RequestBody CropRequest request) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Updating crop {} for userId: {}", cropId, userId);
        
        CropResponse crop = cropService.updateCrop(userId, cropId, request);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop updated successfully",
                crop));
    }

    /**
     * Delete a crop (soft delete).
     */
    @DeleteMapping("/{cropId}")
    public ResponseEntity<ApiResponse<Void>> deleteCrop(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Deleting crop {} for userId: {}", cropId, userId);
        
        cropService.deleteCrop(userId, cropId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop deleted successfully",
                null));
    }

    /**
     * Get crop count for a specific farm.
     */
    @GetMapping("/farm/{farmId}/count")
    public ResponseEntity<ApiResponse<Long>> getCropCount(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting crop count for farmId: {} userId: {}", farmId, userId);
        
        long count = cropService.getCropCount(userId, farmId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop count retrieved successfully",
                count));
    }

    /**
     * Get crops by crop type for the farmer.
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/type/{cropTypeId}")
    public ResponseEntity<ApiResponse<List<CropResponse>>> getCropsByType(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropTypeId,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        
        Long userId = Long.parseLong(userIdHeader);
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting crops by typeId: {} for userId: {} with language: {}", cropTypeId, userId, language);
        
        List<CropResponse> crops = cropService.getCropsByType(userId, cropTypeId, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }

    /**
     * Extract language code from Accept-Language header.
     * Supports formats like "hi", "hi-IN", "en-US", etc.
     * Returns "en", "hi", or "mr" (defaults to "en").
     */
    private String extractLanguage(String acceptLanguage) {
        if (acceptLanguage == null || acceptLanguage.trim().isEmpty()) {
            return "en";
        }
        
        String lang = acceptLanguage.trim().toLowerCase();
        
        // Handle formats like "hi", "hi-IN", "hi,en;q=0.9"
        if (lang.startsWith("hi")) {
            return "hi";
        } else if (lang.startsWith("mr")) {
            return "mr";
        } else {
            return "en"; // Default to English
        }
    }
}

