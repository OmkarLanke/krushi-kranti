package com.krushikranti.auth.controller;

import com.krushikranti.auth.dto.*;
import com.krushikranti.auth.dto.AdminCreateUserRequest;
import com.krushikranti.auth.dto.DeleteUserRequest;
import com.krushikranti.auth.model.User;
import com.krushikranti.auth.service.AuthService;
import com.krushikranti.auth.service.JwtService;
import com.krushikranti.auth.service.RefreshTokenService;
import com.krushikranti.auth.service.UserDeletionService;
import com.krushikranti.i18n.constants.MessageKeys;
import com.krushikranti.i18n.service.MessageService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;
    private final MessageService messageService;
    private final UserDeletionService userDeletionService;
    private final RefreshTokenService refreshTokenService;
    private final JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request, HttpServletRequest httpRequest) {
        try {
            // Send OTP for registration (user is NOT saved yet)
            authService.sendRegistrationOtp(request);
            
            return ResponseEntity.ok(new ApiResponse<>(
                    messageService.getMessage(MessageKeys.AUTH_REGISTRATION_OTP_SENT, httpRequest), 
                    null));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        // Validate that exactly one login method is provided
        boolean isEmailLogin = request.isEmailLogin();
        boolean isPhoneLogin = request.isPhoneLogin();
        
        if (!isEmailLogin && !isPhoneLogin) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(messageService.getMessage(MessageKeys.AUTH_LOGIN_PROVIDE_CREDENTIALS, httpRequest), null));
        }
        
        if (isEmailLogin && isPhoneLogin) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(messageService.getMessage(MessageKeys.AUTH_LOGIN_PROVIDE_CREDENTIALS, httpRequest), null));
        }

        Optional<User> userOpt;
        String errorMessageKey;

        if (isEmailLogin) {
            // Email/Password login
            userOpt = authService.authenticate(request.getEmail(), request.getPassword());
            errorMessageKey = MessageKeys.AUTH_LOGIN_INVALID_EMAIL_PASSWORD;
        } else {
            // Phone/OTP login
            userOpt = authService.authenticateWithOtp(request.getPhoneNumber(), request.getOtp());
            errorMessageKey = MessageKeys.AUTH_LOGIN_INVALID_PHONE_OTP;
        }

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiResponse<>(messageService.getMessage(errorMessageKey, httpRequest), null));
        }

        User user = userOpt.get();
        String accessToken = authService.generateToken(user);
        String refreshToken = refreshTokenService.createRefreshToken(user.getId());

        UserInfo userInfo = UserInfo.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole().name())
                .isVerified(user.getIsVerified())
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtService.getExpirationSeconds())
                .refreshExpiresIn(refreshTokenService.getRefreshExpirationSeconds())
                .user(userInfo)
                .build();

        return ResponseEntity.ok(authResponse);
    }

    /**
     * Refresh access token using a valid refresh token.
     * Returns a new access token and optionally rotates the refresh token.
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@Valid @RequestBody RefreshTokenRequest request, HttpServletRequest httpRequest) {
        try {
            // Validate refresh token and get associated user
            Optional<User> userOpt = refreshTokenService.validateRefreshToken(request.getRefreshToken());

            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ApiResponse<>(messageService.getMessage(MessageKeys.AUTH_REFRESH_TOKEN_INVALID, httpRequest), null));
            }

            User user = userOpt.get();

            // Generate new access token
            String newAccessToken = authService.generateToken(user);

            // Rotate refresh token for additional security
            String newRefreshToken = refreshTokenService.rotateRefreshToken(request.getRefreshToken(), user.getId());

            UserInfo userInfo = UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .phoneNumber(user.getPhoneNumber())
                    .role(user.getRole().name())
                    .isVerified(user.getIsVerified())
                    .build();

            AuthResponse authResponse = AuthResponse.builder()
                    .accessToken(newAccessToken)
                    .refreshToken(newRefreshToken)
                    .tokenType("Bearer")
                    .expiresIn(jwtService.getExpirationSeconds())
                    .refreshExpiresIn(refreshTokenService.getRefreshExpirationSeconds())
                    .user(userInfo)
                    .build();

            log.info("Token refreshed successfully for user: {}", user.getId());
            return ResponseEntity.ok(authResponse);
        } catch (Exception e) {
            log.error("Error refreshing token: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiResponse<>("Invalid or expired refresh token", null));
        }
    }

    /**
     * Logout endpoint - revokes the refresh token.
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody(required = false) RefreshTokenRequest request, HttpServletRequest httpRequest) {
        try {
            if (request != null && request.getRefreshToken() != null && !request.getRefreshToken().isEmpty()) {
                refreshTokenService.revokeToken(request.getRefreshToken());
                log.info("User logged out, refresh token revoked");
            }
            return ResponseEntity.ok(new ApiResponse<>("Logged out successfully", null));
        } catch (Exception e) {
            log.error("Error during logout: {}", e.getMessage());
            // Still return success - logout should not fail
            return ResponseEntity.ok(new ApiResponse<>("Logged out successfully", null));
        }
    }

    @PostMapping("/request-login-otp")
    public ResponseEntity<?> requestLoginOtp(@Valid @RequestBody ResendOtpRequest request, HttpServletRequest httpRequest) {
        try {
            authService.sendLoginOtp(request.getPhoneNumber());
            return ResponseEntity.ok(new ApiResponse<>(
                    messageService.getMessage(MessageKeys.AUTH_LOGIN_OTP_SENT, httpRequest), 
                    null));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(@Valid @RequestBody VerifyOtpRequest request, HttpServletRequest httpRequest) {
        try {
            // Verify OTP and complete registration (user is saved to database with is_verified=true)
            User user = authService.verifyOtpAndRegister(request.getPhoneNumber(), request.getOtp());
            
            UserInfo userInfo = UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .phoneNumber(user.getPhoneNumber())
                    .role(user.getRole().name())
                    .isVerified(user.getIsVerified())
                    .build();

            return ResponseEntity.ok(new ApiResponse<>(
                    messageService.getMessage(MessageKeys.AUTH_REGISTRATION_COMPLETED, httpRequest), 
                    userInfo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Auth Service is running");
    }

    // Test endpoint: Get OTP (for testing purposes only)
    @GetMapping("/get-otp/{phoneNumber}")
    public ResponseEntity<?> getOtp(@PathVariable String phoneNumber) {
        try {
            String otp = authService.getOtpForPhone(phoneNumber);
            if (otp == null) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("No OTP found for this phone number. OTP may have expired or was not generated.", null));
            }
            
            // For testing purposes only - return OTP in response
            return ResponseEntity.ok(new ApiResponse<>(
                    "OTP retrieved successfully. For testing only: " + otp, 
                    otp));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    // Test endpoint: Resend OTP (for testing purposes only)
    @PostMapping("/resend-otp")
    public ResponseEntity<?> resendOtp(@Valid @RequestBody ResendOtpRequest request) {
        try {
            Optional<User> userOpt = authService.findByPhoneNumber(request.getPhoneNumber());
            if (userOpt.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("User not found", null));
            }

            // Generate new OTP
            String otp = authService.generateOtpForPhone(request.getPhoneNumber());
            
            // In production, send OTP via SMS
            // For testing, return it in response (ONLY FOR DEVELOPMENT!)
            return ResponseEntity.ok(new ApiResponse<>(
                    "OTP generated successfully. For testing: " + otp, 
                    null));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Internal endpoint for other services to fetch user details by ID.
     * Used by admin service to get user info (username, email, phone).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserById(@PathVariable Long userId) {
        try {
            Optional<User> userOpt = authService.findById(userId);
            
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>("User not found", null));
            }

            User user = userOpt.get();
            UserInfo userInfo = UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .phoneNumber(user.getPhoneNumber())
                    .role(user.getRole().name())
                    .isVerified(user.getIsVerified())
                    .build();

            return ResponseEntity.ok(userInfo);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Batch endpoint for other services to fetch multiple user details at once.
     * Used for performance optimization to avoid N+1 query problems.
     * 
     * @param userIds Comma-separated list of user IDs, or request body with userIds array
     */
    @PostMapping("/users/batch")
    public ResponseEntity<?> getUsersBatch(@RequestBody BatchUserRequest request) {
        try {
            if (request.getUserIds() == null || request.getUserIds().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("User IDs list cannot be empty", null));
            }

            List<User> users = authService.findByIds(request.getUserIds());
            
            List<UserInfo> userInfos = users.stream()
                    .map(user -> UserInfo.builder()
                            .id(user.getId())
                            .username(user.getUsername())
                            .email(user.getEmail())
                            .phoneNumber(user.getPhoneNumber())
                            .role(user.getRole().name())
                            .isVerified(user.getIsVerified())
                            .build())
                    .toList();

            return ResponseEntity.ok(new ApiResponse<>("Users retrieved successfully", userInfos));
        } catch (Exception e) {
            log.error("Error fetching batch users: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Admin endpoint to create users directly (bypassing OTP verification).
     * Used by admin services to create field officers, etc.
     */
    @PostMapping("/admin/create-user")
    public ResponseEntity<?> adminCreateUser(@Valid @RequestBody AdminCreateUserRequest request) {
        try {
            User.UserRole role;
            try {
                role = User.UserRole.valueOf(request.getRole());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("Invalid role: " + request.getRole(), null));
            }

            User user = authService.registerUserDirectly(
                    request.getUsername(),
                    request.getEmail(),
                    request.getPhoneNumber(),
                    request.getPassword(),
                    role
            );

            UserInfo userInfo = UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .phoneNumber(user.getPhoneNumber())
                    .role(user.getRole().name())
                    .isVerified(user.getIsVerified())
                    .build();

            return ResponseEntity.ok(userInfo);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>(e.getMessage(), null));
        }
    }

    /**
     * Protected endpoint for testing JWT validation through API Gateway.
     * This endpoint requires a valid JWT token.
     * 
     * The gateway will validate the token and add headers:
     * - X-User-Id: User's ID from token
     * - X-User-Roles: User's roles from token
     * - X-Username: User's username from token
     */
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles,
            @RequestHeader(value = "X-Username", required = false) String username,
            HttpServletRequest httpRequest) {
        
        if (userId == null || userId.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new ApiResponse<>("User ID not found in request. Token may not be validated.", null));
        }

        try {
            Long id = Long.parseLong(userId);
            Optional<User> userOpt = authService.findById(id);
            
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>("User not found", null));
            }

            User user = userOpt.get();
            UserInfo userInfo = UserInfo.builder()
                    .id(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .phoneNumber(user.getPhoneNumber())
                    .role(user.getRole().name())
                    .isVerified(user.getIsVerified())
                    .build();

            return ResponseEntity.ok(new ApiResponse<>(
                    messageService.getMessage(MessageKeys.AUTH_USER_RETRIEVED, httpRequest),
                    userInfo));
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse<>("Invalid user ID format", null));
        }
    }

    /**
     * Admin endpoint to delete a user and cascade deletion to all services.
     * Publishes USER_DELETION_EVENTS to Kafka for other services to clean up.
     * 
     * This endpoint should be protected and only accessible by admins.
     */
    @DeleteMapping("/admin/delete-user")
    public ResponseEntity<?> deleteUser(
            @RequestBody DeleteUserRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId) {
        
        try {
            Long deletedBy = null;
            if (adminUserId != null && !adminUserId.isEmpty()) {
                try {
                    deletedBy = Long.parseLong(adminUserId);
                } catch (NumberFormatException e) {
                    // Ignore invalid admin user ID
                }
            }

            boolean deleted = false;
            String identifier = "";

            if (request.getUserId() != null) {
                deleted = userDeletionService.deleteUser(request.getUserId(), request.getReason(), deletedBy);
                identifier = "userId: " + request.getUserId();
            } else if (request.getEmail() != null && !request.getEmail().isEmpty()) {
                deleted = userDeletionService.deleteUserByEmail(request.getEmail(), request.getReason(), deletedBy);
                identifier = "email: " + request.getEmail();
            } else if (request.getPhoneNumber() != null && !request.getPhoneNumber().isEmpty()) {
                deleted = userDeletionService.deleteUserByPhoneNumber(request.getPhoneNumber(), request.getReason(), deletedBy);
                identifier = "phone: " + request.getPhoneNumber();
            } else {
                return ResponseEntity.badRequest()
                        .body(new ApiResponse<>("Must provide userId, email, or phoneNumber", null));
            }

            if (deleted) {
                log.info("User deleted successfully - {}", identifier);
                return ResponseEntity.ok(new ApiResponse<>(
                        "User deleted successfully. Cleanup events published to all services.", null));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>("User not found", null));
            }
        } catch (Exception e) {
            log.error("Error deleting user: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Error deleting user: " + e.getMessage(), null));
        }
    }

    /**
     * Delete user by ID (alternative endpoint for RESTful API style).
     */
    @DeleteMapping("/admin/user/{userId}")
    public ResponseEntity<?> deleteUserById(
            @PathVariable Long userId,
            @RequestParam(required = false) String reason,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId) {
        
        try {
            Long deletedBy = null;
            if (adminUserId != null && !adminUserId.isEmpty()) {
                try {
                    deletedBy = Long.parseLong(adminUserId);
                } catch (NumberFormatException e) {
                    // Ignore invalid admin user ID
                }
            }

            boolean deleted = userDeletionService.deleteUser(userId, reason, deletedBy);

            if (deleted) {
                log.info("User deleted successfully - userId: {}", userId);
                return ResponseEntity.ok(new ApiResponse<>(
                        "User deleted successfully. Cleanup events published to all services.", null));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>("User not found", null));
            }
        } catch (Exception e) {
            log.error("Error deleting user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>("Error deleting user: " + e.getMessage(), null));
        }
    }
}

