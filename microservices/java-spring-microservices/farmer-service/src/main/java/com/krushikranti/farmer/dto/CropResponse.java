package com.krushikranti.farmer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.krushikranti.farmer.model.Crop;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Response DTO for farmer's crop data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropResponse {

    private Long id;
    
    // Farm details
    private Long farmId;
    private String farmName;
    
    // Crop type details
    private Long cropTypeId;
    private String cropTypeName;
    private String cropTypeDisplayName;
    
    // Crop name details
    private Long cropNameId;
    private String cropName;
    private String cropDisplayName;
    private String cropLocalName;
    
    // Area
    private BigDecimal areaAcres;

    // Dates
    private LocalDate sowingDate;
    private LocalDate harvestingDate;

    // Crop Status
    private Crop.CropStatus cropStatus;
    
    // Status
    private Boolean isActive;
    
    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

