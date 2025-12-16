package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.CropName;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for CropName entity (master data).
 */
@Repository
public interface CropNameRepository extends JpaRepository<CropName, Long> {

    /**
     * Find all active crop names for a specific crop type, ordered by display order.
     * Used for farmer app dropdown.
     */
    List<CropName> findByCropTypeIdAndIsActiveTrueOrderByDisplayOrderAsc(Long cropTypeId);

    /**
     * Find all crop names for a specific crop type (for admin).
     */
    List<CropName> findByCropTypeIdOrderByDisplayOrderAsc(Long cropTypeId);

    /**
     * Find all active crop names ordered by crop type and display order.
     */
    @Query("SELECT cn FROM CropName cn WHERE cn.isActive = true ORDER BY cn.cropType.displayOrder, cn.displayOrder")
    List<CropName> findAllActiveOrderedByTypeAndName();

    /**
     * Find crop name by name and crop type ID.
     */
    Optional<CropName> findByNameIgnoreCaseAndCropTypeId(String name, Long cropTypeId);

    /**
     * Check if crop name exists for a crop type.
     */
    boolean existsByNameIgnoreCaseAndCropTypeId(String name, Long cropTypeId);

    /**
     * Check if crop name exists for a crop type excluding a specific ID (for updates).
     */
    boolean existsByNameIgnoreCaseAndCropTypeIdAndIdNot(String name, Long cropTypeId, Long id);

    /**
     * Find active crop name by ID.
     */
    Optional<CropName> findByIdAndIsActiveTrue(Long id);

    /**
     * Count active crop names by crop type.
     */
    long countByCropTypeIdAndIsActiveTrue(Long cropTypeId);

    /**
     * Search crop names by display name or local name containing search term.
     */
    @Query("SELECT cn FROM CropName cn WHERE cn.isActive = true " +
           "AND (LOWER(cn.displayName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) " +
           "OR LOWER(cn.localName) LIKE LOWER(CONCAT('%', :searchTerm, '%'))) " +
           "ORDER BY cn.cropType.displayOrder, cn.displayOrder")
    List<CropName> searchByNameContaining(@Param("searchTerm") String searchTerm);
}

