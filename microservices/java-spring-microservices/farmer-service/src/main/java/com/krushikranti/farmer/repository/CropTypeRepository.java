package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.CropType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for CropType entity (master data).
 */
@Repository
public interface CropTypeRepository extends JpaRepository<CropType, Long> {

    /**
     * Find all active crop types ordered by display order.
     */
    List<CropType> findByIsActiveTrueOrderByDisplayOrderAsc();

    /**
     * Find all crop types ordered by display order (for admin).
     */
    List<CropType> findAllByOrderByDisplayOrderAsc();

    /**
     * Find crop type by type name.
     */
    Optional<CropType> findByTypeName(String typeName);

    /**
     * Find crop type by type name (case insensitive).
     */
    Optional<CropType> findByTypeNameIgnoreCase(String typeName);

    /**
     * Check if crop type exists by type name.
     */
    boolean existsByTypeNameIgnoreCase(String typeName);

    /**
     * Check if crop type exists by type name excluding a specific ID (for updates).
     */
    boolean existsByTypeNameIgnoreCaseAndIdNot(String typeName, Long id);
}

