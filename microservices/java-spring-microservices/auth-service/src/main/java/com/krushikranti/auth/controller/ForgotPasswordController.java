package com.krushikranti.auth.controller;

import com.krushikranti.auth.dto.ApiResponse;
import com.krushikranti.auth.service.PasswordResetService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

/**
 * Controller for password reset functionality
 */
@RestController
@RequestMapping("/auth/forgot-password")
@RequiredArgsConstructor
@Slf4j
public class ForgotPasswordController {

    private final PasswordResetService passwordResetService;

    /**
     * Request password reset - sends email with reset link
     * POST /auth/forgot-password/request
     */
    @PostMapping("/request")
    public ResponseEntity<ApiResponse<String>> requestPasswordReset(
            @Valid @RequestBody ForgotPasswordRequest request) {
        
        log.info("Password reset requested for email: {}", request.getEmail());
        
        try {
            String message = passwordResetService.requestPasswordReset(request.getEmail());
            return ResponseEntity.ok(new ApiResponse<>(message, null));
        } catch (org.springframework.web.server.ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .body(new ApiResponse<>(e.getReason(), null));
        }
    }

    /**
     * Verify reset token validity
     * GET /auth/forgot-password/verify-token?token=xxx
     */
    @GetMapping("/verify-token")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyToken(
            @RequestParam("token") String token) {
        
        log.info("Verifying password reset token");
        
        Optional<Long> userIdOpt = passwordResetService.verifyResetToken(token);
        
        if (userIdOpt.isPresent()) {
            Map<String, Object> data = Map.of(
                    "valid", true,
                    "userId", userIdOpt.get()
            );
            return ResponseEntity.ok(new ApiResponse<>("Token is valid", data));
        } else {
            Map<String, Object> data = Map.of("valid", false);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid or expired token", data));
        }
    }

    /**
     * Reset password using token
     * POST /auth/forgot-password/reset
     */
    @PostMapping("/reset")
    public ResponseEntity<ApiResponse<String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        
        log.info("Password reset requested with token");
        
        try {
            passwordResetService.resetPassword(request.getToken(), request.getNewPassword());
            return ResponseEntity.ok(new ApiResponse<>("Password reset successfully", null));
        } catch (org.springframework.web.server.ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .body(new ApiResponse<>(e.getReason(), null));
        }
    }

    /**
     * Request DTO for forgot password
     */
    @Data
    public static class ForgotPasswordRequest {
        @NotBlank(message = "Email is required")
        @Email(message = "Invalid email format")
        private String email;
    }

    /**
     * Request DTO for reset password
     */
    @Data
    public static class ResetPasswordRequest {
        @NotBlank(message = "Token is required")
        private String token;

        @NotBlank(message = "New password is required")
        @Size(min = 8, message = "Password must be at least 8 characters long")
        private String newPassword;
    }
}
