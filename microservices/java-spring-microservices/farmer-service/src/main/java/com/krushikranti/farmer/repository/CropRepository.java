package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Crop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Crop entity (farmer's crop data).
 */
@Repository
public interface CropRepository extends JpaRepository<Crop, Long> {

    /**
     * Find all active crops for a farm.
     */
    List<Crop> findByFarmIdAndIsActiveTrue(Long farmId);

    /**
     * Find all crops for a farm (including inactive).
     */
    List<Crop> findByFarmId(Long farmId);

    /**
     * Find a specific active crop by ID and farm ID.
     */
    Optional<Crop> findByIdAndFarmIdAndIsActiveTrue(Long cropId, Long farmId);

    /**
     * Find a specific crop by ID and farm ID.
     */
    Optional<Crop> findByIdAndFarmId(Long cropId, Long farmId);

    /**
     * Check if crop exists for a farm with specific crop name.
     */
    boolean existsByFarmIdAndCropNameIdAndIsActiveTrue(Long farmId, Long cropNameId);

    /**
     * Count active crops for a farm.
     */
    long countByFarmIdAndIsActiveTrue(Long farmId);

    /**
     * Find all active crops for a farmer (across all farms).
     */
    @Query("SELECT c FROM Crop c WHERE c.farm.farmer.userId = :userId AND c.isActive = true")
    List<Crop> findByFarmerUserId(@Param("userId") Long userId);

    /**
     * Find crops by crop type for a farmer.
     */
    @Query("SELECT c FROM Crop c WHERE c.farm.farmer.userId = :userId " +
           "AND c.cropName.cropType.id = :cropTypeId AND c.isActive = true")
    List<Crop> findByFarmerUserIdAndCropTypeId(
            @Param("userId") Long userId, 
            @Param("cropTypeId") Long cropTypeId);

    /**
     * Find all active crops for a farmer with farm details.
     */
    @Query("SELECT c FROM Crop c " +
           "JOIN FETCH c.farm f " +
           "JOIN FETCH c.cropName cn " +
           "JOIN FETCH cn.cropType ct " +
           "WHERE f.farmer.userId = :userId AND c.isActive = true AND f.isActive = true")
    List<Crop> findByFarmerUserIdWithDetails(@Param("userId") Long userId);
}

