package com.krushikranti.fieldofficer.repository;

import com.krushikranti.fieldofficer.model.FarmVerification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FarmVerificationRepository extends JpaRepository<FarmVerification, Long> {
    
    /**
     * Find verification by farm ID and field officer ID
     */
    Optional<FarmVerification> findByFarmIdAndFieldOfficerId(Long farmId, Long fieldOfficerId);
    
    /**
     * Find all verifications for a farm
     */
    List<FarmVerification> findByFarmId(Long farmId);
    
    /**
     * Find all verifications by a field officer
     */
    Page<FarmVerification> findByFieldOfficerId(Long fieldOfficerId, Pageable pageable);
    
    /**
     * Find verifications by status
     */
    Page<FarmVerification> findByVerificationStatus(FarmVerification.VerificationStatus status, Pageable pageable);
    
    /**
     * Count verifications by status for a field officer
     */
    long countByFieldOfficerIdAndVerificationStatus(Long fieldOfficerId, FarmVerification.VerificationStatus status);
    
    /**
     * Find verifications for farms assigned to a field officer.
     * Note: This method will need to be implemented by calling farmer-service
     * to get farm IDs, then querying locally. For now, we'll get assignments
     * and then filter verifications by those assignments.
     */
    // TODO: Implement by calling farmer-service REST API to get farm IDs for assigned farmers
    // For now, use findByFieldOfficerId and filter in service layer
}

