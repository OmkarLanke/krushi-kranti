package com.krushikranti.fieldofficer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * DTO for field officer assignments with farm details.
 * Used when field officer views their assigned farms.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldOfficerAssignmentDto {
    private Long assignmentId;
    private Long farmerUserId;
    private String status;
    private String notes;
    private LocalDateTime assignedAt;
    private Long assignedByUserId;
    
    // Farmer Information
    private String farmerName;
    private String farmerPhoneNumber;
    
    // Farm Information (list of farms for this farmer)
    private List<Map<String, Object>> farms;
}

