package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.events.UserDeletionEvent;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import com.krushikranti.fieldofficer.repository.FieldOfficerAssignmentRepository;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import com.krushikranti.fieldofficer.repository.FarmVerificationRepository;
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
 * Cleans up field officer and assignment data when a user is deleted from auth-service.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDeletionConsumer {

    private final FieldOfficerRepository fieldOfficerRepository;
    private final FieldOfficerAssignmentRepository assignmentRepository;
    private final FarmVerificationRepository verificationRepository;

    @KafkaListener(
            topics = "USER_DELETION_EVENTS",
            groupId = "field-officer-service-group",
            containerFactory = "userDeletionKafkaListenerFactory"
    )
    public void consumeUserDeletionEvent(
            @Payload UserDeletionEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {
        
        try {
            log.info("Received user deletion event - Topic: {}, Partition: {}, Offset: {}, UserId: {}, Username: {}, Role: {}",
                    topic, partition, offset, event.getUserId(), event.getUsername(), event.getRole());

            // Handle based on role
            if ("FIELD_OFFICER".equals(event.getRole())) {
                deleteFieldOfficerData(event.getUserId());
            } else if ("FARMER".equals(event.getRole())) {
                deleteFarmerAssignments(event.getUserId());
            }

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
     * Delete all field officer-related data when a field officer user is deleted.
     */
    @Transactional
    public void deleteFieldOfficerData(Long userId) {
        log.info("Starting cleanup of field officer data for userId: {}", userId);

        Optional<FieldOfficer> fieldOfficerOpt = fieldOfficerRepository.findByUserId(userId);
        
        if (fieldOfficerOpt.isEmpty()) {
            log.info("No field officer profile found for userId: {}. Skipping cleanup.", userId);
            return;
        }

        FieldOfficer fieldOfficer = fieldOfficerOpt.get();
        Long fieldOfficerId = fieldOfficer.getId();

        // 1. Delete all verifications done by this field officer
        // Note: This may affect farm verification history - consider soft delete in production
        int verificationsDeleted = verificationRepository.deleteByFieldOfficerId(fieldOfficerId);
        log.info("Deleted {} farm verifications by field officer {} (userId: {})", 
                verificationsDeleted, fieldOfficerId, userId);

        // 2. Cancel all assignments for this field officer
        // Instead of deleting, we update status to CANCELLED to preserve history
        var assignments = assignmentRepository.findByFieldOfficerId(fieldOfficerId, 
                org.springframework.data.domain.Pageable.unpaged());
        for (var assignment : assignments) {
            assignment.setStatus(FieldOfficerAssignment.AssignmentStatus.CANCELLED);
        }
        assignmentRepository.saveAll(assignments.getContent());
        log.info("Cancelled {} assignments for field officer {} (userId: {})", 
                assignments.getTotalElements(), fieldOfficerId, userId);

        // 3. Delete the field officer profile
        fieldOfficerRepository.delete(fieldOfficer);
        log.info("Deleted field officer profile {} for userId: {}", fieldOfficerId, userId);

        log.info("Completed cleanup of field officer data for userId: {}", userId);
    }

    /**
     * Delete/cancel assignments when a farmer user is deleted.
     */
    @Transactional
    public void deleteFarmerAssignments(Long farmerUserId) {
        log.info("Starting cleanup of farmer assignments for farmerUserId: {}", farmerUserId);

        List<FieldOfficerAssignment> assignments = assignmentRepository.findByFarmerUserId(farmerUserId);
        
        if (assignments.isEmpty()) {
            log.info("No assignments found for farmerUserId: {}. Skipping cleanup.", farmerUserId);
            return;
        }

        // Cancel all assignments for this farmer
        for (var assignment : assignments) {
            assignment.setStatus(FieldOfficerAssignment.AssignmentStatus.CANCELLED);
        }
        assignmentRepository.saveAll(assignments);
        log.info("Cancelled {} assignments for farmerUserId: {}", assignments.size(), farmerUserId);

        log.info("Completed cleanup of farmer assignments for farmerUserId: {}", farmerUserId);
    }
}
