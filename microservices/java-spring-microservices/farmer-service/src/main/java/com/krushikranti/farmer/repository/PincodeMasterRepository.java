package com.krushikranti.farmer.repository;

import com.krushikranti.farmer.model.PincodeMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PincodeMasterRepository extends JpaRepository<PincodeMaster, Long> {
    
    List<PincodeMaster> findByPincode(String pincode);
    
    // English queries (default)
    @Query("SELECT DISTINCT p.district FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findDistrictsByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.taluka FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findTalukasByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.state FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findStatesByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.village FROM PincodeMaster p WHERE p.pincode = :pincode ORDER BY p.village")
    List<String> findVillagesByPincode(@Param("pincode") String pincode);
    
    // Hindi queries
    @Query("SELECT DISTINCT COALESCE(p.districtHi, p.district) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findDistrictsByPincodeHi(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.talukaHi, p.taluka) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findTalukasByPincodeHi(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.stateHi, p.state) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findStatesByPincodeHi(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.villageHi, p.village) FROM PincodeMaster p WHERE p.pincode = :pincode ORDER BY COALESCE(p.villageHi, p.village)")
    List<String> findVillagesByPincodeHi(@Param("pincode") String pincode);
    
    // Marathi queries
    @Query("SELECT DISTINCT COALESCE(p.districtMr, p.district) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findDistrictsByPincodeMr(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.talukaMr, p.taluka) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findTalukasByPincodeMr(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.stateMr, p.state) FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findStatesByPincodeMr(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT COALESCE(p.villageMr, p.village) FROM PincodeMaster p WHERE p.pincode = :pincode ORDER BY COALESCE(p.villageMr, p.village)")
    List<String> findVillagesByPincodeMr(@Param("pincode") String pincode);
}

