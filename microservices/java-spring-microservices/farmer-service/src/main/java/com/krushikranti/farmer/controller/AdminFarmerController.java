package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.admin.AdminFarmerDetailDto;
import com.krushikranti.farmer.dto.admin.AdminFarmerListResponse;
import com.krushikranti.farmer.service.AdminFarmerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

/**
 * REST Controller for Admin farmer management operations.
 * All endpoints require ADMIN role (enforced by API Gateway).
 */
@RestController
@RequestMapping("/admin/farmers")
@RequiredArgsConstructor
@Slf4j
public class AdminFarmerController {

    private final AdminFarmerService adminFarmerService;

    /**
     * Get paginated list of all farmers with summary info
     */
    @GetMapping
    public ResponseEntity<ApiResponse<AdminFarmerListResponse>> getAllFarmers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String kycStatus,
            @RequestParam(required = false) String subscriptionStatus,
            @RequestParam(required = false) String pincode,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles) {
        
        log.info("Admin {} fetching farmers list - page: {}, size: {}, search: {}, kyc: {}, sub: {}, pincode: {}",
                adminUserId, page, size, search, kycStatus, subscriptionStatus, pincode);
        
        // Role validation (backup - gateway should already enforce)
        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }
        
        try {
            AdminFarmerListResponse response = adminFarmerService.getAllFarmers(
                    page, size, search, kycStatus, subscriptionStatus, pincode);
            
            return ResponseEntity.ok(new ApiResponse<>("Farmers fetched successfully", response));
        } catch (Exception e) {
            log.error("Error fetching farmers list: ", e);
            return ResponseEntity.internalServerError()
                    .body(new ApiResponse<>("Failed to fetch farmers: " + e.getMessage(), null));
        }
    }

    /**
     * Get detailed information for a single farmer
     */
    @GetMapping("/{farmerId}")
    public ResponseEntity<ApiResponse<AdminFarmerDetailDto>> getFarmerDetail(
            @PathVariable Long farmerId,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles) {
        
        log.info("Admin {} fetching farmer detail for farmerId: {}", adminUserId, farmerId);
        
        // Role validation
        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }
        
        try {
            Optional<AdminFarmerDetailDto> farmerOpt = adminFarmerService.getFarmerDetail(farmerId);
            
            if (farmerOpt.isEmpty()) {
                return ResponseEntity.status(404)
                        .body(new ApiResponse<>("Farmer not found with ID: " + farmerId, null));
            }
            
            return ResponseEntity.ok(new ApiResponse<>("Farmer detail fetched successfully", farmerOpt.get()));
        } catch (Exception e) {
            log.error("Error fetching farmer detail: ", e);
            return ResponseEntity.internalServerError()
                    .body(new ApiResponse<>("Failed to fetch farmer detail: " + e.getMessage(), null));
        }
    }

    /**
     * Get dashboard statistics
     */
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminFarmerListResponse.AdminDashboardStats>> getDashboardStats(
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles) {
        
        log.info("Admin {} fetching dashboard stats", adminUserId);
        
        // Role validation
        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }
        
        try {
            AdminFarmerListResponse.AdminDashboardStats stats = adminFarmerService.getDashboardStats();
            return ResponseEntity.ok(new ApiResponse<>("Dashboard stats fetched successfully", stats));
        } catch (Exception e) {
            log.error("Error fetching dashboard stats: ", e);
            return ResponseEntity.internalServerError()
                    .body(new ApiResponse<>("Failed to fetch stats: " + e.getMessage(), null));
        }
    }
}

