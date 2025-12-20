package com.krushikranti.kyc.repository;

import com.krushikranti.kyc.model.KycVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for KYC verification records.
 */
@Repository
public interface KycVerificationRepository extends JpaRepository<KycVerification, Long> {
    
    Optional<KycVerification> findByUserId(Long userId);
    
    boolean existsByUserId(Long userId);
}

