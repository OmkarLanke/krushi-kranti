package com.krushikranti.farmer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for crop type data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropTypeResponse {

    private Long id;
    private String typeName;
    private String displayName;
    private String description;
    private String iconUrl;
    private Integer displayOrder;
    private Boolean isActive;
    private Long cropNameCount; // Number of crop names under this type
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

