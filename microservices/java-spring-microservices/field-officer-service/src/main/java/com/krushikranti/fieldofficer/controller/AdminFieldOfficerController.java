package com.krushikranti.fieldofficer.controller;

import com.krushikranti.fieldofficer.dto.*;
import com.krushikranti.fieldofficer.service.FieldOfficerAssignmentService;
import com.krushikranti.fieldofficer.service.FieldOfficerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
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
    private final FieldOfficerAssignmentService assignmentService;

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
            @RequestParam(required = false) Boolean isActive,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @RequestHeader(value = "X-User-Roles", required = false) String rolesHeader) {
        try {
            log.debug("Admin fetching field officers - userId: {}, roles: {}, page: {}, size: {}", 
                    userIdHeader, rolesHeader, page, size);
            
            // Log if headers are missing (for debugging)
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.warn("X-User-Id header is missing. This may indicate API Gateway authentication issue.");
            }
            
            Map<String, Object> response = fieldOfficerService.getAllFieldOfficers(page, size, search, isActive);
            return ResponseEntity.ok(new ApiResponse<>("Field officers retrieved successfully", response));
        } catch (Exception e) {
            log.error("Error retrieving field officers: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Get suggested field officers for a farmer based on pincode matching
     */
    @GetMapping("/suggestions/{farmerUserId}")
    public ResponseEntity<ApiResponse<List<SuggestedFieldOfficerDto>>> getSuggestedFieldOfficers(
            @PathVariable Long farmerUserId) {
        try {
            List<SuggestedFieldOfficerDto> suggestions = assignmentService.getSuggestedFieldOfficers(farmerUserId);
            return ResponseEntity.ok(new ApiResponse<>(
                    "Suggested field officers retrieved successfully", suggestions));
        } catch (Exception e) {
            log.error("Error getting suggested field officers for farmer {}: {}", farmerUserId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Assign a field officer to a farmer
     */
    @PostMapping("/assign")
    public ResponseEntity<ApiResponse<AssignmentResponseDto>> assignFieldOfficer(
            @Valid @RequestBody AssignFieldOfficerRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserIdHeader) {
        try {
            log.info("Received assignment request - fieldOfficerId: {}, farmerUserId: {}, farmId: {}, notes: {}", 
                    request.getFieldOfficerId(), request.getFarmerUserId(), request.getFarmId(), request.getNotes());
            
            Long adminUserId = adminUserIdHeader != null ? Long.parseLong(adminUserIdHeader) : null;
            
            AssignmentResponseDto assignment = assignmentService.assignFieldOfficerToFarmer(request, adminUserId);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ApiResponse<>("Field officer assigned successfully", assignment));
        } catch (IllegalArgumentException e) {
            log.warn("Invalid assignment request - fieldOfficerId: {}, farmerUserId: {}, farmId: {}, error: {}", 
                    request.getFieldOfficerId(), request.getFarmerUserId(), request.getFarmId(), e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        } catch (Exception e) {
            log.error("Error assigning field officer - fieldOfficerId: {}, farmerUserId: {}, farmId: {}, error: {}", 
                    request.getFieldOfficerId(), request.getFarmerUserId(), request.getFarmId(), e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Get all assignments for a farmer
     */
    @GetMapping("/assignments")
    public ResponseEntity<ApiResponse<Object>> getAssignments(
            @RequestParam(required = false) Long farmerUserId,
            @RequestParam(required = false) Long fieldOfficerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            if (farmerUserId != null) {
                List<AssignmentResponseDto> assignments = assignmentService.getAssignmentsForFarmer(farmerUserId);
                return ResponseEntity.ok(new ApiResponse<>(
                        "Assignments retrieved successfully", assignments));
            } else if (fieldOfficerId != null) {
                Pageable pageable = PageRequest.of(page, size);
                Page<AssignmentResponseDto> assignmentPage = assignmentService.getAssignmentsForFieldOfficer(
                        fieldOfficerId, pageable);
                
                Map<String, Object> response = new HashMap<>();
                response.put("assignments", assignmentPage.getContent());
                response.put("currentPage", assignmentPage.getNumber());
                response.put("totalPages", assignmentPage.getTotalPages());
                response.put("totalElements", assignmentPage.getTotalElements());
                response.put("pageSize", assignmentPage.getSize());
                response.put("hasNext", assignmentPage.hasNext());
                response.put("hasPrevious", assignmentPage.hasPrevious());
                
                return ResponseEntity.ok(new ApiResponse<>(
                        "Assignments retrieved successfully", response));
            } else {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("Either farmerUserId or fieldOfficerId must be provided", null));
            }
        } catch (Exception e) {
            log.error("Error retrieving assignments: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }
}

