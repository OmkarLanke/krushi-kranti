package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farm;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Farm entity.
 * Provides methods for querying farms by farmer, verification status, etc.
 */
@Repository
public interface FarmRepository extends JpaRepository<Farm, Long> {

    /**
     * Find all active farms for a farmer.
     */
    List<Farm> findByFarmerIdAndIsActiveTrue(Long farmerId);

    /**
     * Find all active farms for a farmer with farmer details (N+1 fix).
     */
    @Query("SELECT f FROM Farm f JOIN FETCH f.farmer WHERE f.farmer.id = :farmerId AND f.isActive = true")
    List<Farm> findByFarmerIdAndIsActiveTrueWithFarmer(@Param("farmerId") Long farmerId);

    /**
     * Find all farms for a farmer (including inactive).
     */
    List<Farm> findByFarmerId(Long farmerId);

    /**
     * Find a specific farm by ID and farmer ID (for ownership verification).
     */
    Optional<Farm> findByIdAndFarmerId(Long farmId, Long farmerId);

    /**
     * Find a specific active farm by ID and farmer ID.
     */
    Optional<Farm> findByIdAndFarmerIdAndIsActiveTrue(Long farmId, Long farmerId);

    /**
     * Check if a farm with the given name exists for a farmer.
     */
    boolean existsByFarmerIdAndFarmNameIgnoreCase(Long farmerId, String farmName);

    /**
     * Check if a farm with the given name exists for a farmer (excluding a specific farm ID).
     * Useful for update validation.
     */
    @Query("SELECT COUNT(f) > 0 FROM Farm f WHERE f.farmer.id = :farmerId AND LOWER(f.farmName) = LOWER(:farmName) AND f.id != :excludeFarmId")
    boolean existsByFarmerIdAndFarmNameIgnoreCaseExcludingId(
            @Param("farmerId") Long farmerId,
            @Param("farmName") String farmName,
            @Param("excludeFarmId") Long excludeFarmId);

    /**
     * Find all verified farms for a farmer.
     */
    List<Farm> findByFarmerIdAndIsVerifiedTrueAndIsActiveTrue(Long farmerId);

    /**
     * Find all unverified farms for a farmer.
     */
    List<Farm> findByFarmerIdAndIsVerifiedFalseAndIsActiveTrue(Long farmerId);

    /**
     * Count total farms for a farmer.
     */
    long countByFarmerIdAndIsActiveTrue(Long farmerId);

    /**
     * Find farms by verification status (for admin/officer queries).
     */
    List<Farm> findByIsVerifiedAndIsActiveTrue(Boolean isVerified);

    /**
     * Find farms by encumbrance status (for loan collateral queries).
     */
    @Query("SELECT f FROM Farm f WHERE f.encumbranceStatus = :status AND f.isActive = true")
    List<Farm> findByEncumbranceStatus(@Param("status") Farm.EncumbranceStatus status);

    /**
     * Find farms that can be used as collateral (verified, free of encumbrance, owned).
     */
    @Query("SELECT f FROM Farm f WHERE f.farmer.id = :farmerId " +
           "AND f.isVerified = true " +
           "AND f.encumbranceStatus = 'FREE' " +
           "AND f.landOwnership IN ('OWNED', 'GOVERNMENT_ALLOTTED') " +
           "AND f.isActive = true")
    List<Farm> findValidCollateralFarms(@Param("farmerId") Long farmerId);
    
    /**
     * Count farms by farmer ID
     */
    long countByFarmerId(Long farmerId);
    
    /**
     * Count verified farms by farmer ID (only active farms)
     */
    @Query("SELECT COUNT(f) FROM Farm f WHERE f.farmer.id = :farmerId AND f.isVerified = true AND f.isActive = true")
    long countByFarmerIdAndIsVerifiedTrue(@Param("farmerId") Long farmerId);

        @Query("SELECT f.farmer.id, COUNT(f) FROM Farm f WHERE f.farmer.id IN :farmerIds GROUP BY f.farmer.id")
        List<Object[]> countByFarmerIdsGrouped(@Param("farmerIds") List<Long> farmerIds);

        @Query("SELECT f.farmer.id, COUNT(f) FROM Farm f " +
            "WHERE f.farmer.id IN :farmerIds AND f.isVerified = true AND f.isActive = true " +
            "GROUP BY f.farmer.id")
        List<Object[]> countVerifiedByFarmerIdsGrouped(@Param("farmerIds") List<Long> farmerIds);
    
    /**
     * Count all verified farms
     */
    long countByIsVerifiedTrue();
}

