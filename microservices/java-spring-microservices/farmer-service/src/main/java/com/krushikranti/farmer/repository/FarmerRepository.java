package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.Farmer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
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

        @Query("SELECT f FROM Farmer f WHERE " +
            "(:search IS NULL OR :search = '' OR " +
            "LOWER(f.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "LOWER(f.lastName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "LOWER(f.village) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "LOWER(f.district) LIKE LOWER(CONCAT('%', :search, '%'))) AND " +
            "(:pincode IS NULL OR :pincode = '' OR LOWER(f.pincode) = LOWER(:pincode))")
        Page<Farmer> findWithAdminFilters(
             @Param("search") String search,
             @Param("pincode") String pincode,
             Pageable pageable);

        @Query("SELECT DISTINCT f.state FROM Farmer f WHERE f.state IS NOT NULL AND f.state <> '' ORDER BY f.state")
        List<String> findDistinctStates();

        @Query("SELECT DISTINCT f.district FROM Farmer f WHERE f.district IS NOT NULL AND f.district <> '' ORDER BY f.district")
        List<String> findDistinctDistricts();

        @Query("SELECT DISTINCT f.village FROM Farmer f WHERE f.village IS NOT NULL AND f.village <> '' ORDER BY f.village")
        List<String> findDistinctVillages();

        @Query("SELECT DISTINCT f.pincode FROM Farmer f WHERE f.pincode IS NOT NULL AND f.pincode <> '' ORDER BY f.pincode")
        List<String> findDistinctPincodes();
}

