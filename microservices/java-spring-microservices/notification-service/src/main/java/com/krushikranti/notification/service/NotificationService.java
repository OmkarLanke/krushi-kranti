package com.krushikranti.notification.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.krushikranti.notification.events.NotificationEvent;
import com.krushikranti.notification.model.Notification;
import com.krushikranti.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    
    private final NotificationRepository notificationRepository;
    private final ObjectMapper objectMapper;
    
    /**
     * Process notification event from Kafka and store in database
     */
    @Transactional
    public Notification processNotificationEvent(NotificationEvent event) {
        log.info("Processing notification event - Type: {}, Recipient User ID: {}, Title: {}",
                event.getEventType(), event.getRecipientUserId(), event.getTitle());
        
        try {
            // Convert data map to JSON string
            String dataJson = null;
            if (event.getData() != null && !event.getData().isEmpty()) {
                dataJson = objectMapper.writeValueAsString(event.getData());
            }
            
            Notification notification = Notification.builder()
                    .eventType(event.getEventType())
                    .recipientUserId(event.getRecipientUserId())
                    .recipientPhoneNumber(event.getRecipientPhoneNumber())
                    .title(event.getTitle())
                    .message(event.getMessage())
                    .data(dataJson)
                    .priority(event.getPriority() != null ? event.getPriority() : "MEDIUM")
                    .isRead(false)
                    .createdAt(event.getTimestamp() != null ? event.getTimestamp() : LocalDateTime.now())
                    .build();
            
            Notification saved = notificationRepository.save(notification);
            log.info("Notification saved successfully - ID: {}, Recipient User ID: {}, Type: {}",
                    saved.getId(), saved.getRecipientUserId(), saved.getEventType());
            
            return saved;
        } catch (JsonProcessingException e) {
            log.error("Error converting notification data to JSON - Event Type: {}, Recipient User ID: {}, Error: {}",
                    event.getEventType(), event.getRecipientUserId(), e.getMessage(), e);
            throw new RuntimeException("Failed to process notification event", e);
        }
    }
    
    /**
     * Get notifications for a user with pagination
     */
    public Page<Notification> getNotificationsByUserId(Long userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return notificationRepository.findByRecipientUserIdOrderByCreatedAtDesc(userId, pageable);
    }
    
    /**
     * Get unread notifications for a user
     */
    public List<Notification> getUnreadNotificationsByUserId(Long userId) {
        return notificationRepository.findByRecipientUserIdAndIsReadFalseOrderByCreatedAtDesc(userId);
    }
    
    /**
     * Get unread count for a user
     */
    public Long getUnreadCountByUserId(Long userId) {
        return notificationRepository.countByRecipientUserIdAndIsReadFalse(userId);
    }
    
    /**
     * Get unread notifications by type for a user
     */
    public List<Notification> getUnreadNotificationsByType(Long userId, String eventType) {
        log.info("Fetching unread notifications - User ID: {}, Event Type: {}", userId, eventType);
        List<Notification> notifications = notificationRepository.findUnreadByRecipientAndType(userId, eventType);
        
        // Additional safety check: Verify all notifications belong to the requested user
        List<Notification> verified = notifications.stream()
                .filter(n -> n.getRecipientUserId().equals(userId))
                .toList();
        
        if (notifications.size() != verified.size()) {
            log.error("CRITICAL: Query returned {} notifications but only {} belong to User ID: {}", 
                    notifications.size(), verified.size(), userId);
        }
        
        log.info("Returning {} verified notifications for User ID: {}, Event Type: {}", 
                verified.size(), userId, eventType);
        return verified;
    }
    
    /**
     * Mark notification as read
     */
    @Transactional
    public boolean markAsRead(Long notificationId, Long userId) {
        int updated = notificationRepository.markAsRead(notificationId, userId, LocalDateTime.now());
        if (updated > 0) {
            log.info("Notification marked as read - ID: {}, User ID: {}", notificationId, userId);
            return true;
        }
        log.warn("Notification not found or already read - ID: {}, User ID: {}", notificationId, userId);
        return false;
    }
    
    /**
     * Mark all notifications as read for a user
     */
    @Transactional
    public int markAllAsRead(Long userId) {
        int updated = notificationRepository.markAllAsRead(userId, LocalDateTime.now());
        log.info("Marked {} notifications as read for User ID: {}", updated, userId);
        return updated;
    }
    
    /**
     * Get notification by ID and user ID
     */
    public Notification getNotificationByIdAndUserId(Long notificationId, Long userId) {
        return notificationRepository.findByIdAndRecipientUserId(notificationId, userId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Notification not found with ID: " + notificationId + " for User ID: " + userId));
    }
}
