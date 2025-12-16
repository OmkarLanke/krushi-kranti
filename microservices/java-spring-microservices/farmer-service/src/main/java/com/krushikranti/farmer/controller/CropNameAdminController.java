package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.CropNameRequest;
import com.krushikranti.farmer.dto.CropNameResponse;
import com.krushikranti.farmer.service.CropNameService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin REST Controller for managing Crop Names (master data).
 * Only accessible by ADMIN role.
 */
@RestController
@RequestMapping("/farmer/admin/crop-names")
@RequiredArgsConstructor
@Slf4j
public class CropNameAdminController {

    private final CropNameService cropNameService;

    /**
     * Get all crop names for a specific crop type (for admin).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> getCropNames(
            @RequestParam(required = false) Long typeId) {
        log.debug("Admin: Getting crop names for typeId: {}", typeId);
        
        List<CropNameResponse> cropNames;
        if (typeId != null) {
            cropNames = cropNameService.getAllCropNamesByTypeId(typeId);
        } else {
            cropNames = cropNameService.getAllActiveCropNames();
        }
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
    }

    /**
     * Get a specific crop name by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CropNameResponse>> getCropNameById(@PathVariable Long id) {
        log.debug("Admin: Getting crop name with ID: {}", id);
        CropNameResponse cropName = cropNameService.getCropNameById(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop name retrieved successfully",
                cropName));
    }

    /**
     * Search crop names by term.
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> searchCropNames(
            @RequestParam String term) {
        log.debug("Admin: Searching crop names with term: {}", term);
        List<CropNameResponse> cropNames = cropNameService.searchCropNames(term);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
    }

    /**
     * Create a new crop name.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<CropNameResponse>> createCropName(
            @Valid @RequestBody CropNameRequest request) {
        log.debug("Admin: Creating crop name: {}", request.getName());
        CropNameResponse cropName = cropNameService.createCropName(request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(
                        "Crop name created successfully",
                        cropName));
    }

    /**
     * Update an existing crop name.
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CropNameResponse>> updateCropName(
            @PathVariable Long id,
            @Valid @RequestBody CropNameRequest request) {
        log.debug("Admin: Updating crop name with ID: {}", id);
        CropNameResponse cropName = cropNameService.updateCropName(id, request);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop name updated successfully",
                cropName));
    }

    /**
     * Soft delete a crop name.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCropName(@PathVariable Long id) {
        log.debug("Admin: Deleting crop name with ID: {}", id);
        cropNameService.deleteCropName(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop name deleted successfully",
                null));
    }

    /**
     * Restore a deleted crop name.
     */
    @PostMapping("/{id}/restore")
    public ResponseEntity<ApiResponse<CropNameResponse>> restoreCropName(@PathVariable Long id) {
        log.debug("Admin: Restoring crop name with ID: {}", id);
        CropNameResponse cropName = cropNameService.restoreCropName(id);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop name restored successfully",
                cropName));
    }
}

