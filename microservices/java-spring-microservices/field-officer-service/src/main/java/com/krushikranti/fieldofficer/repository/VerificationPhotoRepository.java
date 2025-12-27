package com.krushikranti.fieldofficer.repository;

import com.krushikranti.fieldofficer.model.VerificationPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VerificationPhotoRepository extends JpaRepository<VerificationPhoto, Long> {
    
    /**
     * Find all photos for a verification
     */
    List<VerificationPhoto> findByVerificationId(Long verificationId);
    
    /**
     * Delete all photos for a verification
     */
    void deleteByVerificationId(Long verificationId);
}

