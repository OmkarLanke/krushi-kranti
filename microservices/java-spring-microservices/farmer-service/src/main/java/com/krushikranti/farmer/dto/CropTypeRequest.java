package com.krushikranti.farmer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for creating/updating crop types (admin only).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropTypeRequest {

    @NotBlank(message = "Type name is required")
    @Size(max = 50, message = "Type name cannot exceed 50 characters")
    private String typeName;

    @NotBlank(message = "Display name is required")
    @Size(max = 100, message = "Display name cannot exceed 100 characters")
    private String displayName;

    @Size(max = 500, message = "Description cannot exceed 500 characters")
    private String description;

    private String iconUrl;

    private Integer displayOrder;

    private Boolean isActive;
}

