package com.krushikranti.kyc.repository;

import com.krushikranti.kyc.model.KycVerificationLog;
import com.krushikranti.kyc.model.VerificationType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for KYC verification logs.
 */
@Repository
public interface KycVerificationLogRepository extends JpaRepository<KycVerificationLog, Long> {
    
    List<KycVerificationLog> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<KycVerificationLog> findByUserIdAndVerificationTypeOrderByCreatedAtDesc(
            Long userId, VerificationType verificationType);
}

