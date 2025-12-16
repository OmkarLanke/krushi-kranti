package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farmer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FarmerRepository extends JpaRepository<Farmer, Long> {
    
    Optional<Farmer> findByUserId(Long userId);
    
    boolean existsByUserId(Long userId);
}

