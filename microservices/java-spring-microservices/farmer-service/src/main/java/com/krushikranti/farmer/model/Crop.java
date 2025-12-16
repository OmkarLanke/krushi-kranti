package com.krushikranti.farmer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entity representing a farmer's crop on a specific farm.
 * Links to Farm and references CropName master table.
 */
@Entity
@Table(name = "crops")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Crop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "crop_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farm_id", nullable = false)
    private Farm farm;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "crop_name_id", nullable = false)
    private CropName cropName;

    @Column(name = "area_acres", nullable = false, precision = 10, scale = 2)
    private BigDecimal areaAcres;

    @Column(name = "sowing_date")
    private LocalDate sowingDate;

    @Column(name = "harvesting_date")
    private LocalDate harvestingDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "crop_status", length = 20)
    @Builder.Default
    private CropStatus cropStatus = CropStatus.PLANNED;

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

    /**
     * Enum representing the status of a crop.
     */
    public enum CropStatus {
        PLANNED,    // Crop is planned but not yet sown
        SOWN,       // Seeds have been planted
        GROWING,    // Crop is actively growing
        HARVESTED,  // Crop has been harvested
        FAILED      // Crop failed due to weather/pests/disease
    }
}

