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
    
    @Query("SELECT DISTINCT p.district FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findDistrictsByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.taluka FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findTalukasByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.state FROM PincodeMaster p WHERE p.pincode = :pincode")
    List<String> findStatesByPincode(@Param("pincode") String pincode);
    
    @Query("SELECT DISTINCT p.village FROM PincodeMaster p WHERE p.pincode = :pincode ORDER BY p.village")
    List<String> findVillagesByPincode(@Param("pincode") String pincode);
}

