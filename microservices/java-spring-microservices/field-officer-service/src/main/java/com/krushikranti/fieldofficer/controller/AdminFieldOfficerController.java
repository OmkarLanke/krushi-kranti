package com.krushikranti.fieldofficer.controller;

import com.krushikranti.fieldofficer.dto.ApiResponse;
import com.krushikranti.fieldofficer.dto.CreateFieldOfficerRequest;
import com.krushikranti.fieldofficer.dto.FieldOfficerSummaryDto;
import com.krushikranti.fieldofficer.service.FieldOfficerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Admin controller for Field Officer management.
 */
@RestController
@RequestMapping("/admin/field-officers")
@RequiredArgsConstructor
@Slf4j
public class AdminFieldOfficerController {

    private final FieldOfficerService fieldOfficerService;

    /**
     * Create a new field officer
     */
    @PostMapping
    public ResponseEntity<ApiResponse<FieldOfficerSummaryDto>> createFieldOfficer(
            @Valid @RequestBody CreateFieldOfficerRequest request) {
        try {
            FieldOfficerSummaryDto created = fieldOfficerService.createFieldOfficer(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ApiResponse<>("Field officer created successfully", created));
        } catch (Exception e) {
            log.error("Error creating field officer: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Get paginated list of all field officers
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllFieldOfficers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive) {
        try {
            Map<String, Object> response = fieldOfficerService.getAllFieldOfficers(page, size, search, isActive);
            return ResponseEntity.ok(new ApiResponse<>("Field officers retrieved successfully", response));
        } catch (Exception e) {
            log.error("Error retrieving field officers: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }
}

