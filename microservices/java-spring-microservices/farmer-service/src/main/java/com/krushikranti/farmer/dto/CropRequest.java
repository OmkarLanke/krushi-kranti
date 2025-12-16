package com.krushikranti.farmer.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.krushikranti.farmer.model.Crop;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Request DTO for farmer to add/update crops on their farm.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropRequest {

    @NotNull(message = "Farm ID is required")
    private Long farmId;

    @NotNull(message = "Crop name ID is required")
    private Long cropNameId;

    @NotNull(message = "Area in acres is required")
    @DecimalMin(value = "0.01", message = "Area must be greater than 0")
    @Digits(integer = 8, fraction = 2, message = "Area must have at most 8 digits before decimal and 2 after")
    private BigDecimal areaAcres;

    private LocalDate sowingDate;

    private LocalDate harvestingDate;

    private Crop.CropStatus cropStatus;
}

