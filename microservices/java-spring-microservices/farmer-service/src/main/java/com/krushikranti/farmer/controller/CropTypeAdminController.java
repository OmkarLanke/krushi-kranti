package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.CropTypeRequest;
import com.krushikranti.farmer.dto.CropTypeResponse;
import com.krushikranti.farmer.service.CropTypeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin REST Controller for managing Crop Types (master data).
 * Only accessible by ADMIN role.
 */
@RestController
@RequestMapping("/farmer/admin/crop-types")
@RequiredArgsConstructor
@Slf4j
public class CropTypeAdminController {

    private final CropTypeService cropTypeService;

    /**
     * Get all crop types (including inactive) for admin.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CropTypeResponse>>> getAllCropTypes() {
        log.debug("Admin: Getting all crop types");
        List<CropTypeResponse> cropTypes = cropTypeService.getAllCropTypes();
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop types retrieved successfully",
                cropTypes));
    }

    /**
     * Get a specific crop type by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CropTypeResponse>> getCropTypeById(@PathVariable Long id) {
        log.debug("Admin: Getting crop type with ID: {}", id);
        CropTypeResponse cropType = cropTypeService.getCropTypeById(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop type retrieved successfully",
                cropType));
    }

    /**
     * Create a new crop type.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<CropTypeResponse>> createCropType(
            @Valid @RequestBody CropTypeRequest request) {
        log.debug("Admin: Creating crop type: {}", request.getTypeName());
        CropTypeResponse cropType = cropTypeService.createCropType(request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(
                        "Crop type created successfully",
                        cropType));
    }

    /**
     * Update an existing crop type.
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CropTypeResponse>> updateCropType(
            @PathVariable Long id,
            @Valid @RequestBody CropTypeRequest request) {
        log.debug("Admin: Updating crop type with ID: {}", id);
        CropTypeResponse cropType = cropTypeService.updateCropType(id, request);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop type updated successfully",
                cropType));
    }

    /**
     * Soft delete a crop type.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCropType(@PathVariable Long id) {
        log.debug("Admin: Deleting crop type with ID: {}", id);
        cropTypeService.deleteCropType(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop type deleted successfully",
                null));
    }

    /**
     * Restore a deleted crop type.
     */
    @PostMapping("/{id}/restore")
    public ResponseEntity<ApiResponse<CropTypeResponse>> restoreCropType(@PathVariable Long id) {
        log.debug("Admin: Restoring crop type with ID: {}", id);
        CropTypeResponse cropType = cropTypeService.restoreCropType(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop type restored successfully",
                cropType));
    }
}

