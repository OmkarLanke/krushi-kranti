package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farmer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FarmerRepository extends JpaRepository<Farmer, Long> {
    
    Optional<Farmer> findByUserId(Long userId);
    
    boolean existsByUserId(Long userId);
    
    /**
     * Search farmers by name, village, district
     */
    @Query("SELECT f FROM Farmer f WHERE " +
           "LOWER(f.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.lastName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.village) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.district) LIKE LOWER(CONCAT('%', :search, '%'))")
    Page<Farmer> searchFarmers(@Param("search") String search, Pageable pageable);
}

