package com.krushikranti.fieldofficer.repository;

import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public interface FieldOfficerAssignmentRepository extends JpaRepository<FieldOfficerAssignment, Long> {
    
    /**
     * Find all assignments for a field officer
     */
    Page<FieldOfficerAssignment> findByFieldOfficerId(Long fieldOfficerId, Pageable pageable);
    
    /**
     * Find all assignments for a farmer
     */
    List<FieldOfficerAssignment> findByFarmerUserId(Long farmerUserId);

    /**
     * Find all assignments for a farmer with pagination
     */
    Page<FieldOfficerAssignment> findByFarmerUserId(Long farmerUserId, Pageable pageable);
    
    /**
     * Find active assignment for a field officer and farmer
     */
    @Query("SELECT a FROM FieldOfficerAssignment a WHERE " +
           "a.fieldOfficerId = :fieldOfficerId AND " +
           "a.farmerUserId = :farmerUserId AND " +
           "a.status != 'CANCELLED'")
    Optional<FieldOfficerAssignment> findActiveAssignment(
        @Param("fieldOfficerId") Long fieldOfficerId,
        @Param("farmerUserId") Long farmerUserId
    );
    
    /**
     * Find assignments by status
     */
    Page<FieldOfficerAssignment> findByStatus(FieldOfficerAssignment.AssignmentStatus status, Pageable pageable);
    
    /**
     * Count active assignments for a field officer
     */
    long countByFieldOfficerIdAndStatusNot(Long fieldOfficerId, FieldOfficerAssignment.AssignmentStatus status);

    /**
     * Count assignments for a field officer by exact status.
     */
    long countByFieldOfficerIdAndStatus(Long fieldOfficerId, FieldOfficerAssignment.AssignmentStatus status);

    /**
     * Count farm-level assignments (farmId present) for a field officer by exact status.
     */
    long countByFieldOfficerIdAndFarmIdIsNotNullAndStatus(Long fieldOfficerId, FieldOfficerAssignment.AssignmentStatus status);

    /**
     * Count active farm-level assignments (farmId present and non-cancelled).
     */
    long countByFieldOfficerIdAndFarmIdIsNotNullAndStatusNot(Long fieldOfficerId, FieldOfficerAssignment.AssignmentStatus status);

    /**
     * Find all assignments for multiple farmers (batch query for admin dashboard)
     */
    @Query("SELECT a FROM FieldOfficerAssignment a WHERE a.farmerUserId IN :farmerUserIds")
    List<FieldOfficerAssignment> findByFarmerUserIdIn(@Param("farmerUserIds") List<Long> farmerUserIds);

        @Query("SELECT a.fieldOfficerId, COUNT(a) FROM FieldOfficerAssignment a " +
            "WHERE a.fieldOfficerId IN :fieldOfficerIds AND a.farmId IS NOT NULL AND a.status = 'ASSIGNED' " +
            "GROUP BY a.fieldOfficerId")
        List<Object[]> countAssignedByFieldOfficerIds(@Param("fieldOfficerIds") List<Long> fieldOfficerIds);

        @Query("SELECT a.fieldOfficerId, COUNT(a) FROM FieldOfficerAssignment a " +
            "WHERE a.fieldOfficerId IN :fieldOfficerIds AND a.farmId IS NOT NULL AND a.status = 'COMPLETED' " +
            "GROUP BY a.fieldOfficerId")
        List<Object[]> countVerifiedByFieldOfficerIds(@Param("fieldOfficerIds") List<Long> fieldOfficerIds);

            @Query("SELECT a.fieldOfficerId, COUNT(a) FROM FieldOfficerAssignment a " +
                "WHERE a.fieldOfficerId IN :fieldOfficerIds AND a.farmId IS NOT NULL AND a.status <> 'CANCELLED' " +
                "GROUP BY a.fieldOfficerId")
            List<Object[]> countActiveFarmAssignmentsByFieldOfficerIds(@Param("fieldOfficerIds") List<Long> fieldOfficerIds);
    
    /**
     * Find active assignment for a specific farm
     * Used to check if a farm is already assigned to another field officer
     */
    @Query("SELECT a FROM FieldOfficerAssignment a WHERE " +
           "a.farmId = :farmId AND " +
           "a.status != 'CANCELLED'")
    Optional<FieldOfficerAssignment> findActiveAssignmentByFarmId(
        @Param("farmId") Long farmId
    );
    
    /**
     * Find active assignment for a field officer and farm
     */
    @Query("SELECT a FROM FieldOfficerAssignment a WHERE " +
           "a.fieldOfficerId = :fieldOfficerId AND " +
           "a.farmId = :farmId AND " +
           "a.status != 'CANCELLED'")
    Optional<FieldOfficerAssignment> findActiveAssignmentByFieldOfficerAndFarm(
        @Param("fieldOfficerId") Long fieldOfficerId,
        @Param("farmId") Long farmId
    );
}

