package com.krushikranti.farmer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for crop name data.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropNameResponse {

    private Long id;
    private Long cropTypeId;
    private String cropTypeName;
    private String cropTypeDisplayName;
    private String name;
    private String displayName;
    private String localName;
    private String description;
    private String iconUrl;
    private Integer displayOrder;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

