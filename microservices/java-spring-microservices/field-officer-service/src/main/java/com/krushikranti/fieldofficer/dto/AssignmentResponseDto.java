package com.krushikranti.fieldofficer.dto;

import com.krushikranti.fieldofficer.model.FieldOfficerAssignment;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for field officer assignment response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssignmentResponseDto {
    
    private Long assignmentId;
    private Long fieldOfficerId;
    private Long farmerUserId;
    private Long farmId; // Farm ID from farmer-service
    
    // Field Officer Info
    private String fieldOfficerName;
    private String fieldOfficerPhone;
    private String fieldOfficerPincode;
    
    // Farmer Info (for admin view)
    private String farmerName;
    private String farmerPhone;
    private String farmName;
    private String farmLocation; // Village, District, State
    
    // Assignment Info
    private String status;
    private Long assignedByUserId;
    private LocalDateTime assignedAt;
    private LocalDateTime completedAt;
    private String notes;
    
    public static AssignmentResponseDto fromEntity(FieldOfficerAssignment assignment, 
                                                   String fieldOfficerName, 
                                                   String fieldOfficerPhone,
                                                   String fieldOfficerPincode) {
        return fromEntity(assignment, fieldOfficerName, fieldOfficerPhone, fieldOfficerPincode, null, null, null, null);
    }
    
    public static AssignmentResponseDto fromEntity(FieldOfficerAssignment assignment, 
                                                   String fieldOfficerName, 
                                                   String fieldOfficerPhone,
                                                   String fieldOfficerPincode,
                                                   String farmerName,
                                                   String farmerPhone,
                                                   String farmName,
                                                   String farmLocation) {
        return AssignmentResponseDto.builder()
                .assignmentId(assignment.getId())
                .fieldOfficerId(assignment.getFieldOfficerId())
                .farmerUserId(assignment.getFarmerUserId())
                .farmId(assignment.getFarmId())
                .fieldOfficerName(fieldOfficerName)
                .fieldOfficerPhone(fieldOfficerPhone)
                .fieldOfficerPincode(fieldOfficerPincode)
                .farmerName(farmerName)
                .farmerPhone(farmerPhone)
                .farmName(farmName)
                .farmLocation(farmLocation)
                .status(assignment.getStatus() != null ? assignment.getStatus().name() : null)
                .assignedByUserId(assignment.getAssignedByUserId())
                .assignedAt(assignment.getAssignedAt())
                .completedAt(assignment.getCompletedAt())
                .notes(assignment.getNotes())
                .build();
    }
}

