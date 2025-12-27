package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for assigning a field officer to a farmer
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssignFieldOfficerRequest {
    
    @NotNull(message = "Field officer ID is required")
    private Long fieldOfficerId;
    
    @NotNull(message = "Farmer user ID is required")
    private Long farmerUserId;
    
    private String notes; // Optional notes for the assignment
}

