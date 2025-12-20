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
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/crop-types")
    public ResponseEntity<ApiResponse<List<CropTypeResponse>>> getActiveCropTypes(
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting active crop types for dropdown with language: {}", language);
        List<CropTypeResponse> cropTypes = cropTypeService.getActiveCropTypes(language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop types retrieved successfully",
                cropTypes));
    }

    /**
     * Get active crop names for a specific crop type (Dropdown 2).
     * When user selects "Vegetables", this returns: Tomato, Onion, Potato, etc.
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/crop-names")
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> getActiveCropNamesByType(
            @RequestParam Long typeId,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        String language = extractLanguage(acceptLanguage);
        log.debug("Getting active crop names for typeId: {} with language: {}", typeId, language);
        List<CropNameResponse> cropNames = cropNameService.getActiveCropNamesByTypeId(typeId, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
    }

    /**
     * Search crop names by term (for autocomplete/search).
     * Supports language translation via Accept-Language header (en, hi, mr).
     */
    @GetMapping("/crop-names/search")
    public ResponseEntity<ApiResponse<List<CropNameResponse>>> searchCropNames(
            @RequestParam String term,
            @RequestHeader(value = "Accept-Language", required = false, defaultValue = "en") String acceptLanguage) {
        String language = extractLanguage(acceptLanguage);
        log.debug("Searching crop names with term: {} and language: {}", term, language);
        List<CropNameResponse> cropNames = cropNameService.searchCropNames(term, language);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Crop names retrieved successfully",
                cropNames));
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

