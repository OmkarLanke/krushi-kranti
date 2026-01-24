package com.krushikranti.subscription.service;

import com.krushikranti.subscription.events.UserDeletionEvent;
import com.krushikranti.subscription.model.PaymentTransaction;
import com.krushikranti.subscription.model.Subscription;
import com.krushikranti.subscription.repository.PaymentTransactionRepository;
import com.krushikranti.subscription.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Kafka consumer for processing user deletion events.
 * Cleans up all subscription-related data when a user is deleted from auth-service.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDeletionConsumer {

    private final SubscriptionRepository subscriptionRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;

    @KafkaListener(
            topics = "USER_DELETION_EVENTS",
            groupId = "subscription-service-group",
            containerFactory = "userDeletionKafkaListenerFactory"
    )
    public void consumeUserDeletionEvent(
            @Payload UserDeletionEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {
        
        try {
            log.info("Received user deletion event - Topic: {}, Partition: {}, Offset: {}, UserId: {}, Username: {}",
                    topic, partition, offset, event.getUserId(), event.getUsername());

            deleteUserData(event.getUserId());

            // Acknowledge message processing
            acknowledgment.acknowledge();

            log.info("Successfully processed user deletion event - UserId: {}, Username: {}",
                    event.getUserId(), event.getUsername());

        } catch (Exception e) {
            log.error("Error processing user deletion event - UserId: {}, Error: {}",
                    event.getUserId(), e.getMessage(), e);
            // Don't acknowledge on error - message will be retried
        }
    }

    /**
     * Delete all subscription-related data for a user.
     * Order: Payment Transactions -> Subscriptions
     */
    @Transactional
    public void deleteUserData(Long userId) {
        log.info("Starting cleanup of subscription data for userId: {}", userId);

        // Find subscriptions for this user
        Optional<Subscription> subscriptionOpt = subscriptionRepository.findByUserId(userId);
        
        if (subscriptionOpt.isEmpty()) {
            log.info("No subscription found for userId: {}. Skipping cleanup.", userId);
            return;
        }

        Subscription subscription = subscriptionOpt.get();

        // 1. Delete all payment transactions for this subscription
        List<PaymentTransaction> transactions = paymentTransactionRepository.findByUserId(userId);
        if (!transactions.isEmpty()) {
            paymentTransactionRepository.deleteAll(transactions);
            log.info("Deleted {} payment transactions for userId: {}", transactions.size(), userId);
        }

        // 2. Delete the subscription
        subscriptionRepository.delete(subscription);
        log.info("Deleted subscription {} for userId: {}", subscription.getId(), userId);

        log.info("Completed cleanup of subscription data for userId: {}. Deleted: {} transactions, 1 subscription",
                userId, transactions.size());
    }
}
