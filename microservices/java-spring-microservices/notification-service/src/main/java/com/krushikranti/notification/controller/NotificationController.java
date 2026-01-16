package com.krushikranti.notification.controller;

import com.krushikranti.notification.model.Notification;
import com.krushikranti.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * REST API for farmers to fetch their notifications
 */
@RestController
@RequestMapping("/notification")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {
    
    private final NotificationService notificationService;
    
    /**
     * Get all notifications for a user with pagination
     * GET /notification?userId=123&page=0&size=20
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getNotifications(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            Page<Notification> notifications = notificationService.getNotificationsByUserId(userId, page, size);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Notifications retrieved successfully");
            response.put("data", Map.of(
                    "notifications", notifications.getContent(),
                    "totalElements", notifications.getTotalElements(),
                    "totalPages", notifications.getTotalPages(),
                    "currentPage", notifications.getNumber(),
                    "pageSize", notifications.getSize(),
                    "hasNext", notifications.hasNext(),
                    "hasPrevious", notifications.hasPrevious()
            ));
            
            return ResponseEntity.ok(response);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error retrieving notifications: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    /**
     * Get unread notifications for a user
     * GET /notification/unread
     */
    @GetMapping("/unread")
    public ResponseEntity<Map<String, Object>> getUnreadNotifications(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            List<Notification> notifications = notificationService.getUnreadNotificationsByUserId(userId);
            Long unreadCount = notificationService.getUnreadCountByUserId(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Unread notifications retrieved successfully");
            response.put("data", Map.of(
                    "notifications", notifications,
                    "unreadCount", unreadCount
            ));
            
            return ResponseEntity.ok(response);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error retrieving unread notifications: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    /**
     * Get unread notifications by type (e.g., FARM_VERIFICATION_OTP)
     * GET /notification/unread/FARM_VERIFICATION_OTP
     */
    @GetMapping("/unread/{eventType}")
    public ResponseEntity<Map<String, Object>> getUnreadNotificationsByType(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @PathVariable String eventType) {
        
        log.info("=== GET UNREAD NOTIFICATIONS BY TYPE ===");
        log.info("Event Type: {}", eventType);
        log.info("X-User-Id header: {}", userIdHeader);
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                log.error("CRITICAL: Missing X-User-Id header - returning 401");
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            log.info("Parsed User ID: {}", userId);
            
            // CRITICAL: Filter by recipientUserId to ensure only this user's notifications are returned
            List<Notification> notifications = notificationService.getUnreadNotificationsByType(userId, eventType);
            
            // Additional safety check: Verify all notifications belong to the requested user
            List<Notification> verifiedNotifications = notifications.stream()
                    .filter(n -> n.getRecipientUserId().equals(userId))
                    .toList();
            
            if (notifications.size() != verifiedNotifications.size()) {
                log.error("CRITICAL SECURITY ISSUE: Found {} notifications but only {} belong to User ID: {}. Filtering out invalid ones.",
                        notifications.size(), verifiedNotifications.size(), userId);
            }
            
            log.info("Found {} unread notifications for User ID: {}, Event Type: {} (verified: {})", 
                    notifications.size(), userId, eventType, verifiedNotifications.size());
            
            // Log each notification's recipientUserId for debugging
            for (Notification n : verifiedNotifications) {
                log.info("Notification ID: {}, Recipient User ID: {}, Event Type: {}, OTP: {}",
                        n.getId(), n.getRecipientUserId(), n.getEventType(), 
                        n.getData() != null ? "present" : "null");
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Unread notifications by type retrieved successfully");
            response.put("data", Map.of(
                    "notifications", verifiedNotifications, // Use verified list
                    "count", verifiedNotifications.size()
            ));
            
            log.info("Returning response with {} verified notifications for User ID: {}", 
                    verifiedNotifications.size(), userId);
            return ResponseEntity.ok(response);
        } catch (NumberFormatException e) {
            log.error("Invalid user ID format: {}", userIdHeader, e);
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error retrieving unread notifications by type: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    /**
     * Get unread count for a user
     * GET /notification/unread-count
     */
    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Object>> getUnreadCount(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            Long unreadCount = notificationService.getUnreadCountByUserId(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Unread count retrieved successfully");
            response.put("data", Map.of("unreadCount", unreadCount));
            
            return ResponseEntity.ok(response);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error retrieving unread count: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    /**
     * Mark notification as read
     * PUT /notification/{notificationId}/read
     */
    @PutMapping("/{notificationId}/read")
    public ResponseEntity<Map<String, Object>> markAsRead(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader,
            @PathVariable Long notificationId) {
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            boolean updated = notificationService.markAsRead(notificationId, userId);
            
            if (updated) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Notification marked as read");
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(404)
                        .body(createErrorResponse("Notification not found or already read"));
            }
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error marking notification as read: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    /**
     * Mark all notifications as read for a user
     * PUT /notification/read-all
     */
    @PutMapping("/read-all")
    public ResponseEntity<Map<String, Object>> markAllAsRead(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        
        try {
            if (userIdHeader == null || userIdHeader.trim().isEmpty()) {
                return ResponseEntity.status(401)
                        .body(createErrorResponse("Unauthorized: Missing user identification"));
            }
            
            Long userId = Long.parseLong(userIdHeader.trim());
            int updated = notificationService.markAllAsRead(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "All notifications marked as read");
            response.put("data", Map.of("updatedCount", updated));
            
            return ResponseEntity.ok(response);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse("Invalid user ID format: " + userIdHeader));
        } catch (Exception e) {
            log.error("Error marking all notifications as read: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("An unexpected error occurred: " + e.getMessage()));
        }
    }
    
    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return response;
    }
}
