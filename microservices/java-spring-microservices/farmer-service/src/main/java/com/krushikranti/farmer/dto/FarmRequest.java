package com.krushikranti.farmer.dto;

import com.krushikranti.farmer.model.Farm;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Request DTO for creating/updating farm details.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FarmRequest {

    // ========================================
    // BASIC FARM INFORMATION (Required)
    // ========================================
    
    @NotBlank(message = "Farm name is required")
    @Size(max = 200, message = "Farm name cannot exceed 200 characters")
    private String farmName;

    private Farm.FarmType farmType;

    @NotNull(message = "Total area in acres is required")
    @DecimalMin(value = "0.01", message = "Total area must be greater than 0")
    @Digits(integer = 8, fraction = 2, message = "Total area must have at most 8 digits before decimal and 2 after")
    private BigDecimal totalAreaAcres;

    // Address
    @NotBlank(message = "Pincode is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "Pincode must be 6 digits")
    private String pincode;

    @NotBlank(message = "Village is required")
    @Size(max = 200, message = "Village cannot exceed 200 characters")
    private String village;

    // Land Details
    private Farm.SoilType soilType;

    private Farm.IrrigationType irrigationType;

    @NotNull(message = "Land ownership is required")
    private Farm.LandOwnership landOwnership;

    // ========================================
    // COLLATERAL INFORMATION (Optional)
    // ========================================
    
    @Size(max = 100, message = "Survey number cannot exceed 100 characters")
    private String surveyNumber;

    @Size(max = 200, message = "Land registration number cannot exceed 200 characters")
    private String landRegistrationNumber;

    @Size(max = 100, message = "Patta number cannot exceed 100 characters")
    private String pattaNumber;

    @DecimalMin(value = "0", message = "Estimated land value cannot be negative")
    @Digits(integer = 13, fraction = 2, message = "Estimated land value must have at most 13 digits before decimal and 2 after")
    private BigDecimal estimatedLandValue;

    private Farm.EncumbranceStatus encumbranceStatus;

    @Size(max = 1000, message = "Encumbrance remarks cannot exceed 1000 characters")
    private String encumbranceRemarks;

    // Document URLs (S3 via File Service)
    private String landDocumentUrl;

    private String surveyMapUrl;

    private String registrationCertificateUrl;
}

