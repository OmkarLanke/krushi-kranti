package com.krushikranti.notification.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications", indexes = {
    @Index(name = "idx_user_id", columnList = "recipient_user_id"),
    @Index(name = "idx_type", columnList = "event_type"),
    @Index(name = "idx_read_status", columnList = "is_read"),
    @Index(name = "idx_created_at", columnList = "created_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Notification {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType;
    
    @Column(name = "recipient_user_id", nullable = false)
    private Long recipientUserId;
    
    @Column(name = "recipient_phone_number", length = 15)
    private String recipientPhoneNumber;
    
    @Column(name = "title", nullable = false, length = 200)
    private String title;
    
    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;
    
    @Column(name = "data", columnDefinition = "TEXT")
    private String data; // JSON string of additional data
    
    @Column(name = "priority", length = 10)
    @Builder.Default
    private String priority = "MEDIUM";
    
    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
    
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
