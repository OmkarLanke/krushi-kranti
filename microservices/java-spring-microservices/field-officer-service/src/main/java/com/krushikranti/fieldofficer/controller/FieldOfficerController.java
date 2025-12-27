package com.krushikranti.fieldofficer.controller;

import com.krushikranti.fieldofficer.dto.ApiResponse;
import com.krushikranti.fieldofficer.service.FieldOfficerProfileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Field Officer facing controller for their own operations.
 */
@RestController
@RequestMapping("/field-officer")
@RequiredArgsConstructor
@Slf4j
public class FieldOfficerController {

    private final FieldOfficerProfileService fieldOfficerProfileService;

    /**
     * Get field officer's own profile
     */
    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<Object>> getProfile(
            @RequestHeader("X-User-Id") String userIdHeader) {
        try {
            Long userId = Long.parseLong(userIdHeader);
            Map<String, Object> profile = fieldOfficerProfileService.getProfile(userId);
            return ResponseEntity.ok(new ApiResponse<>("Profile retrieved successfully", profile));
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format", null));
        } catch (RuntimeException e) {
            log.error("Error retrieving profile: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Field Officer Service is running");
    }
}

