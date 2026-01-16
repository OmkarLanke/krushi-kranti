package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.FarmRequest;
import com.krushikranti.farmer.dto.FarmResponse;
import com.krushikranti.farmer.service.FarmService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST Controller for Farm management.
 * All endpoints are protected and require JWT token via API Gateway.
 */
@RestController
@RequestMapping("/farmer/profile/farms")
@RequiredArgsConstructor
@Slf4j
public class FarmController {

    private final FarmService farmService;

    /**
     * Get all farms for the logged-in farmer.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<FarmResponse>>> getAllFarms(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting all farms for userId: {}", userId);
        
        List<FarmResponse> farms = farmService.getFarmsByUserId(userId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farms retrieved successfully",
                farms));
    }

    /**
     * Get a specific farm by ID.
     */
    @GetMapping("/{farmId}")
    public ResponseEntity<ApiResponse<FarmResponse>> getFarmById(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting farm {} for userId: {}", farmId, userId);
        
        FarmResponse farm = farmService.getFarmById(userId, farmId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farm retrieved successfully",
                farm));
    }

    /**
     * Create a new farm.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<FarmResponse>> createFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @Valid @RequestBody FarmRequest request) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Creating farm for userId: {}", userId);
        
        FarmResponse farm = farmService.createFarm(userId, request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(
                        "Farm created successfully",
                        farm));
    }

    /**
     * Update an existing farm.
     */
    @PutMapping("/{farmId}")
    public ResponseEntity<ApiResponse<FarmResponse>> updateFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId,
            @Valid @RequestBody FarmRequest request) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Updating farm {} for userId: {}", farmId, userId);
        
        FarmResponse farm = farmService.updateFarm(userId, farmId, request);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farm updated successfully",
                farm));
    }

    /**
     * Delete a farm (soft delete).
     */
    @DeleteMapping("/{farmId}")
    public ResponseEntity<ApiResponse<Void>> deleteFarm(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long farmId) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Deleting farm {} for userId: {}", farmId, userId);
        
        farmService.deleteFarm(userId, farmId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farm deleted successfully",
                null));
    }

    /**
     * Get count of farms for the logged-in farmer.
     */
    @GetMapping("/count")
    public ResponseEntity<ApiResponse<Long>> getFarmCount(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting farm count for userId: {}", userId);
        
        long count = farmService.getFarmCount(userId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farm count retrieved successfully",
                count));
    }

    /**
     * Get all farms that are valid for use as loan collateral.
     * A farm is valid collateral if:
     * - It is verified by an on-field officer
     * - It has no encumbrances (FREE status)
     * - It is owned or government allotted
     * - It has an estimated land value > 0
     */
    @GetMapping("/collateral")
    public ResponseEntity<ApiResponse<List<FarmResponse>>> getValidCollateralFarms(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting valid collateral farms for userId: {}", userId);
        
        List<FarmResponse> farms = farmService.getValidCollateralFarms(userId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Valid collateral farms retrieved successfully",
                farms));
    }

    /**
     * Update farm verification status (internal endpoint for field-officer-service).
     * This endpoint is called by field-officer-service after farm verification.
     */
    @PutMapping("/{farmId}/verification")
    public ResponseEntity<ApiResponse<Void>> updateFarmVerificationStatus(
            @PathVariable Long farmId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @RequestBody Map<String, Object> request) {
        
        log.info("=== RECEIVED FARM VERIFICATION STATUS UPDATE REQUEST ===");
        log.info("Farm ID: {}, Request: {}, Headers - X-User-Id: {}", farmId, request, userIdHeader);
        
        Boolean isVerified = (Boolean) request.get("isVerified");
        Long verifiedByOfficerId = null;
        if (request.get("verifiedByOfficerId") != null) {
            try {
                Object officerIdObj = request.get("verifiedByOfficerId");
                if (officerIdObj instanceof Number) {
                    verifiedByOfficerId = ((Number) officerIdObj).longValue();
                } else {
                    verifiedByOfficerId = Long.parseLong(officerIdObj.toString());
                }
            } catch (Exception e) {
                log.warn("Could not parse verifiedByOfficerId: {}", request.get("verifiedByOfficerId"));
            }
        }
        String verificationRemarks = (String) request.get("verificationRemarks");
        
        if (isVerified == null) {
            log.error("isVerified field is missing in request");
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("isVerified field is required", null));
        }
        
        log.info("Updating verification status for farm {}: isVerified={}, verifiedBy={}, remarks={}", 
                farmId, isVerified, verifiedByOfficerId, verificationRemarks);
        
        try {
            farmService.updateFarmVerificationStatus(farmId, isVerified, verifiedByOfficerId, verificationRemarks);
            log.info("=== SUCCESSFULLY UPDATED FARM VERIFICATION STATUS ===");
            log.info("Farm ID: {}, isVerified: {}", farmId, isVerified);
        } catch (Exception e) {
            log.error("=== ERROR UPDATING FARM VERIFICATION STATUS ===");
            log.error("Farm ID: {}, Error: {}", farmId, e.getMessage(), e);
            throw e;
        }
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farm verification status updated successfully",
                null));
    }
}

