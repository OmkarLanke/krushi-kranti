package com.krushikranti.notification.service;

import com.krushikranti.notification.events.NotificationEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

/**
 * Kafka consumer for processing notification events from NOTIFICATION_EVENTS topic
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationConsumer {
    
    private final NotificationService notificationService;
    
    @KafkaListener(topics = "NOTIFICATION_EVENTS", groupId = "notification-service-group")
    public void consumeNotificationEvent(
            @Payload NotificationEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {
        
        try {
            log.info("Received notification event - Topic: {}, Partition: {}, Offset: {}, Event Type: {}, Recipient User ID: {}",
                    topic, partition, offset, event.getEventType(), event.getRecipientUserId());
            
            // Process and store notification
            notificationService.processNotificationEvent(event);
            
            // Acknowledge message processing
            acknowledgment.acknowledge();
            
            log.info("Successfully processed notification event - Event Type: {}, Recipient User ID: {}",
                    event.getEventType(), event.getRecipientUserId());
            
        } catch (Exception e) {
            log.error("Error processing notification event - Event Type: {}, Recipient User ID: {}, Error: {}",
                    event.getEventType(), event.getRecipientUserId(), e.getMessage(), e);
            // Don't acknowledge on error - message will be retried
            // In production, you might want to send to a dead letter queue
        }
    }
}
