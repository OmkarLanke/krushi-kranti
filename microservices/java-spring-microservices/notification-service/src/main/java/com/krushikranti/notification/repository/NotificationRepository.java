package com.krushikranti.notification.repository;

import com.krushikranti.notification.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    Page<Notification> findByRecipientUserIdOrderByCreatedAtDesc(Long recipientUserId, Pageable pageable);
    
    List<Notification> findByRecipientUserIdAndIsReadFalseOrderByCreatedAtDesc(Long recipientUserId);
    
    Long countByRecipientUserIdAndIsReadFalse(Long recipientUserId);
    
    Optional<Notification> findByIdAndRecipientUserId(Long id, Long recipientUserId);
    
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = :readAt WHERE n.id = :id AND n.recipientUserId = :recipientUserId")
    int markAsRead(@Param("id") Long id, @Param("recipientUserId") Long recipientUserId, @Param("readAt") LocalDateTime readAt);
    
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = :readAt WHERE n.recipientUserId = :recipientUserId AND n.isRead = false")
    int markAllAsRead(@Param("recipientUserId") Long recipientUserId, @Param("readAt") LocalDateTime readAt);
    
    @Query("SELECT n FROM Notification n WHERE n.recipientUserId = :recipientUserId AND n.eventType = :eventType AND n.isRead = false ORDER BY n.createdAt DESC")
    List<Notification> findUnreadByRecipientAndType(@Param("recipientUserId") Long recipientUserId, @Param("eventType") String eventType);
}
