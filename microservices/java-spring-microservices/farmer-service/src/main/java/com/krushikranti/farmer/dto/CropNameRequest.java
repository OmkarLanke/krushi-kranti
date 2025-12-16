package com.krushikranti.farmer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for creating/updating crop names (admin only).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropNameRequest {

    @NotNull(message = "Crop type ID is required")
    private Long cropTypeId;

    @NotBlank(message = "Name is required")
    @Size(max = 100, message = "Name cannot exceed 100 characters")
    private String name;

    @NotBlank(message = "Display name is required")
    @Size(max = 150, message = "Display name cannot exceed 150 characters")
    private String displayName;

    @Size(max = 150, message = "Local name cannot exceed 150 characters")
    private String localName;

    @Size(max = 500, message = "Description cannot exceed 500 characters")
    private String description;

    private String iconUrl;

    private Integer displayOrder;

    private Boolean isActive;
}

