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
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CropResponse>>> getAllCrops(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting all crops for userId: {}", userId);
        
        List<CropResponse> crops = cropService.getAllCropsByUserId(userId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }

    /**
     * Get all crops for a specific farm.
     */
    @GetMapping("/farm/{farmId}")
    public ResponseEntity<ApiResponse<List<CropResponse>>> getCropsByFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting crops for farmId: {} userId: {}", farmId, userId);
        
        List<CropResponse> crops = cropService.getCropsByFarmId(userId, farmId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }

    /**
     * Get a specific crop by ID.
     */
    @GetMapping("/{cropId}")
    public ResponseEntity<ApiResponse<CropResponse>> getCropById(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting crop {} for userId: {}", cropId, userId);
        
        CropResponse crop = cropService.getCropById(userId, cropId);
        
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
     */
    @GetMapping("/type/{cropTypeId}")
    public ResponseEntity<ApiResponse<List<CropResponse>>> getCropsByType(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long cropTypeId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting crops by typeId: {} for userId: {}", cropTypeId, userId);
        
        List<CropResponse> crops = cropService.getCropsByType(userId, cropTypeId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crops retrieved successfully",
                crops));
    }
}

