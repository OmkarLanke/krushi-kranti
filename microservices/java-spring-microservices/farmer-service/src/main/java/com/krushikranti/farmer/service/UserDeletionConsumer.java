package com.krushikranti.farmer.service;

import com.krushikranti.farmer.events.UserDeletionEvent;
import com.krushikranti.farmer.model.Crop;
import com.krushikranti.farmer.model.Farm;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.CropRepository;
import com.krushikranti.farmer.repository.FarmRepository;
import com.krushikranti.farmer.repository.FarmerRepository;
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
 * Cleans up all farmer-related data when a user is deleted from auth-service.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDeletionConsumer {

    private final FarmerRepository farmerRepository;
    private final FarmRepository farmRepository;
    private final CropRepository cropRepository;

    @KafkaListener(
            topics = "USER_DELETION_EVENTS",
            groupId = "farmer-service-group",
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

            // Only process if it's a FARMER role or process all roles
            // You might want to filter by role if needed
            deleteUserData(event.getUserId());

            // Acknowledge message processing
            acknowledgment.acknowledge();

            log.info("Successfully processed user deletion event - UserId: {}, Username: {}",
                    event.getUserId(), event.getUsername());

        } catch (Exception e) {
            log.error("Error processing user deletion event - UserId: {}, Error: {}",
                    event.getUserId(), e.getMessage(), e);
            // Don't acknowledge on error - message will be retried
            // Consider implementing dead letter queue for persistent failures
        }
    }

    /**
     * Delete all farmer-related data for a user.
     * Order: Crops -> Farms -> Farmer profile
     */
    @Transactional
    public void deleteUserData(Long userId) {
        log.info("Starting cleanup of farmer data for userId: {}", userId);

        // Find the farmer profile
        Optional<Farmer> farmerOpt = farmerRepository.findByUserId(userId);
        
        if (farmerOpt.isEmpty()) {
            log.info("No farmer profile found for userId: {}. Skipping cleanup.", userId);
            return;
        }

        Farmer farmer = farmerOpt.get();
        Long farmerId = farmer.getId();

        // 1. Delete all crops for all farms of this farmer
        List<Farm> farms = farmRepository.findByFarmerId(farmerId);
        int cropsDeleted = 0;
        for (Farm farm : farms) {
            List<Crop> crops = cropRepository.findByFarmId(farm.getId());
            cropRepository.deleteAll(crops);
            cropsDeleted += crops.size();
        }
        log.info("Deleted {} crops for farmer {} (userId: {})", cropsDeleted, farmerId, userId);

        // 2. Delete all farms for this farmer
        farmRepository.deleteAll(farms);
        log.info("Deleted {} farms for farmer {} (userId: {})", farms.size(), farmerId, userId);

        // 3. Delete the farmer profile
        farmerRepository.delete(farmer);
        log.info("Deleted farmer profile {} for userId: {}", farmerId, userId);

        log.info("Completed cleanup of farmer data for userId: {}. Deleted: {} crops, {} farms, 1 farmer profile",
                userId, cropsDeleted, farms.size());
    }
}
