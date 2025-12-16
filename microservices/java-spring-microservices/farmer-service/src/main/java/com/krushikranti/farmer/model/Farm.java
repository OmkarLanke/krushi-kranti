package com.krushikranti.farmer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entity representing a farm owned/operated by a farmer.
 * Used as collateral information for loan approval.
 */
@Entity
@Table(name = "farms")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Farm {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "farm_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private Farmer farmer;

    // ========================================
    // BASIC FARM INFORMATION
    // ========================================
    
    @Column(name = "farm_name", nullable = false, length = 200)
    private String farmName;

    @Enumerated(EnumType.STRING)
    @Column(name = "farm_type", length = 50)
    private FarmType farmType;

    @Column(name = "total_area_acres", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAreaAcres;

    // Address
    @Column(nullable = false, length = 6)
    private String pincode;

    @Column(nullable = false, length = 200)
    private String village;

    @Column(nullable = false, length = 100)
    private String district;

    @Column(nullable = false, length = 100)
    private String taluka;

    @Column(nullable = false, length = 100)
    private String state;

    // Land Details
    @Enumerated(EnumType.STRING)
    @Column(name = "soil_type", length = 50)
    private SoilType soilType;

    @Enumerated(EnumType.STRING)
    @Column(name = "irrigation_type", length = 50)
    private IrrigationType irrigationType;

    @Enumerated(EnumType.STRING)
    @Column(name = "land_ownership", nullable = false, length = 50)
    private LandOwnership landOwnership;

    // ========================================
    // COLLATERAL INFORMATION
    // ========================================
    
    @Column(name = "survey_number", length = 100)
    private String surveyNumber;

    @Column(name = "land_registration_number", length = 200)
    private String landRegistrationNumber;

    @Column(name = "patta_number", length = 100)
    private String pattaNumber;

    @Column(name = "estimated_land_value", precision = 15, scale = 2)
    private BigDecimal estimatedLandValue;

    @Enumerated(EnumType.STRING)
    @Column(name = "encumbrance_status", length = 50)
    @Builder.Default
    private EncumbranceStatus encumbranceStatus = EncumbranceStatus.NOT_VERIFIED;

    @Column(name = "encumbrance_remarks", columnDefinition = "TEXT")
    private String encumbranceRemarks;

    // Document URLs (S3 via File Service)
    @Column(name = "land_document_url", columnDefinition = "TEXT")
    private String landDocumentUrl;

    @Column(name = "survey_map_url", columnDefinition = "TEXT")
    private String surveyMapUrl;

    @Column(name = "registration_certificate_url", columnDefinition = "TEXT")
    private String registrationCertificateUrl;

    // ========================================
    // VERIFICATION STATUS
    // ========================================
    
    @Column(name = "is_verified")
    @Builder.Default
    private Boolean isVerified = false;

    @Column(name = "verified_by")
    private Long verifiedBy; // On-field Officer user ID

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "verification_remarks", columnDefinition = "TEXT")
    private String verificationRemarks;

    // ========================================
    // STATUS & METADATA
    // ========================================
    
    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // ========================================
    // ENUMS
    // ========================================
    
    public enum FarmType {
        ORGANIC,
        CONVENTIONAL,
        MIXED,
        VERMI_COMPOST
    }

    public enum SoilType {
        BLACK,
        RED,
        SANDY,
        LOAMY,
        CLAY,
        MIXED
    }

    public enum IrrigationType {
        DRIP,
        SPRINKLER,
        RAINFED,
        CANAL,
        BORE_WELL,
        OPEN_WELL,
        MIXED
    }

    public enum LandOwnership {
        OWNED,
        LEASED,
        SHARED,
        GOVERNMENT_ALLOTTED
    }

    public enum EncumbranceStatus {
        NOT_VERIFIED,
        FREE,
        ENCUMBERED,
        PARTIALLY_ENCUMBERED
    }
}

