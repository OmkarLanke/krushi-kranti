package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.CropNameResponse;
import com.krushikranti.farmer.dto.CropTypeResponse;
import com.krushikranti.farmer.service.CropNameService;
import com.krushikranti.farmer.service.CropTypeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST Controller for farmer app to get crop master data (read-only).
 * Used for populating dropdowns in the farmer app.
 */
@RestController
@RequestMapping("/farmer/profile")
@RequiredArgsConstructor
@Slf4j
public class CropMasterController {

    private final CropTypeService cropTypeService;
    private final CropNameService cropNameService;

    /**
     * Get all active crop types for dropdown (Dropdown 1).
     * Returns: Vegetables, Fruits, Grains, etc.
     */
    @GetMapping("/crop-types")
    public ResponseEntity<ApiResponse<List<CropTypeResponse>>> getActiveCropTypes() {
        log.debug("Getting active crop types for dropdown");
        List<CropTypeResponse> cropTypes = cropTypeService.getActiveCropTypes();
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop types retrieved successfully",
                cropTypes));
    }

    /**
     * Get active crop names for a specific crop type (Dropdown 2).
     * When user selects "Vegetables", this returns: Tomato, Onion, Potato, etc.
     */
    @GetMapping("/crop-names")
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> getActiveCropNamesByType(
            @RequestParam Long typeId) {
        log.debug("Getting active crop names for typeId: {}", typeId);
        List<CropNameResponse> cropNames = cropNameService.getActiveCropNamesByTypeId(typeId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
    }

    /**
     * Search crop names by term (for autocomplete/search).
     */
    @GetMapping("/crop-names/search")
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> searchCropNames(
            @RequestParam String term) {
        log.debug("Searching crop names with term: {}", term);
        List<CropNameResponse> cropNames = cropNameService.searchCropNames(term);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
    }
}

