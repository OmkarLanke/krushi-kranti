package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.service.PincodeImportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for pincode data import (Admin/Development use only).
 * This should be secured or removed in production.
 */
@RestController
@RequestMapping("/farmer/admin")
@RequiredArgsConstructor
@Slf4j
public class PincodeImportController {

    private final PincodeImportService pincodeImportService;

    /**
     * Import pincode data from Excel file.
     * This is a one-time operation to populate the pincode_master table.
     * 
     * @param filePath Full path to the Excel file
     * @return Number of records imported
     */
    @PostMapping("/pincode/import")
    public ResponseEntity<ApiResponse<Integer>> importPincodes(@RequestParam("filePath") String filePath) {
        log.info("Importing pincodes from file: {}", filePath);
        
        int importedCount = pincodeImportService.importFromExcel(filePath);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Pincode import completed successfully",
                importedCount));
    }

    /**
     * Get count of pincode records in database.
     */
    @GetMapping("/pincode/count")
    public ResponseEntity<ApiResponse<Long>> getPincodeCount() {
        long count = pincodeImportService.getPincodeCount();
        return ResponseEntity.ok(new ApiResponse<>(
                "Pincode count retrieved",
                count));
    }
}

