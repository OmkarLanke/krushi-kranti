package com.krushikranti.farmer.dto;

import com.krushikranti.farmer.model.Farm;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Response DTO for farm details.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FarmResponse {

    private Long id;
    private Long farmerId;

    // ========================================
    // BASIC FARM INFORMATION
    // ========================================
    
    private String farmName;
    private Farm.FarmType farmType;
    private BigDecimal totalAreaAcres;

    // Address
    private String pincode;
    private String village;
    private String district;
    private String taluka;
    private String state;

    // Land Details
    private Farm.SoilType soilType;
    private Farm.IrrigationType irrigationType;
    private Farm.LandOwnership landOwnership;

    // ========================================
    // COLLATERAL INFORMATION
    // ========================================
    
    private String surveyNumber;
    private String landRegistrationNumber;
    private String pattaNumber;
    private BigDecimal estimatedLandValue;
    private Farm.EncumbranceStatus encumbranceStatus;
    private String encumbranceRemarks;

    // Document URLs
    private String landDocumentUrl;
    private String surveyMapUrl;
    private String registrationCertificateUrl;

    // ========================================
    // VERIFICATION STATUS
    // ========================================
    
    private Boolean isVerified;
    private Long verifiedBy;
    private LocalDateTime verifiedAt;
    private String verificationRemarks;

    // ========================================
    // GPS LOCATION COORDINATES
    // ========================================
    
    private BigDecimal farmLatitude;
    private BigDecimal farmLongitude;
    private BigDecimal farmLocationAccuracy;
    private LocalDateTime farmLocationCapturedAt;

    // ========================================
    // STATUS & METADATA
    // ========================================
    
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Check if this farm is valid for use as loan collateral.
     */
    public boolean isValidCollateral() {
        return Boolean.TRUE.equals(isVerified) 
                && encumbranceStatus == Farm.EncumbranceStatus.FREE
                && (landOwnership == Farm.LandOwnership.OWNED 
                    || landOwnership == Farm.LandOwnership.GOVERNMENT_ALLOTTED)
                && estimatedLandValue != null 
                && estimatedLandValue.compareTo(BigDecimal.ZERO) > 0;
    }
}

