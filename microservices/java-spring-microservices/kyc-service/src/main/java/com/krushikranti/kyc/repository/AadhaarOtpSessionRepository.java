package com.krushikranti.kyc.repository;

import com.krushikranti.kyc.model.AadhaarOtpSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for Aadhaar OTP sessions.
 */
@Repository
public interface AadhaarOtpSessionRepository extends JpaRepository<AadhaarOtpSession, Long> {
    
    Optional<AadhaarOtpSession> findByUserIdAndRequestIdAndOtpVerifiedFalse(Long userId, String requestId);
    
    Optional<AadhaarOtpSession> findTopByUserIdOrderByCreatedAtDesc(Long userId);
    
    void deleteByUserId(Long userId);
}

