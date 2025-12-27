package com.krushikranti.fieldofficer.repository;

import com.krushikranti.fieldofficer.model.FieldOfficer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FieldOfficerRepository extends JpaRepository<FieldOfficer, Long> {
    
    Optional<FieldOfficer> findByUserId(Long userId);
    
    boolean existsByUserId(Long userId);
    
    /**
     * Search field officers by name, village, district
     */
    @Query("SELECT f FROM FieldOfficer f WHERE " +
           "LOWER(f.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.lastName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.village) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.district) LIKE LOWER(CONCAT('%', :search, '%'))")
    Page<FieldOfficer> searchFieldOfficers(@Param("search") String search, Pageable pageable);
    
    Page<FieldOfficer> findByIsActive(Boolean isActive, Pageable pageable);
}

