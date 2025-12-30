package com.krushikranti.fieldofficer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Represents the assignment of a Field Officer to a Farmer.
 * Admin assigns field officers to farmers for farm verification.
 */
@Entity
@Table(name = "field_officer_assignments")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldOfficerAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "assignment_id")
    private Long id;

    @Column(name = "field_officer_id", nullable = false)
    private Long fieldOfficerId;

    @Column(name = "farmer_user_id", nullable = false)
    private Long farmerUserId; // Links to auth.users.id (farmer)

    @Column(name = "farm_id")
    private Long farmId; // Links to farmer-service farms table. If NULL, assignment is for all farms of the farmer.

    @Column(name = "status", length = 20)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private AssignmentStatus status = AssignmentStatus.ASSIGNED;

    @Column(name = "assigned_by_user_id")
    private Long assignedByUserId; // Admin who assigned

    @Column(name = "assigned_at", updatable = false)
    private LocalDateTime assignedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "notes", length = 1000)
    private String notes;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        assignedAt = LocalDateTime.now();
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum AssignmentStatus {
        ASSIGNED,      // Field officer assigned, verification pending
        IN_PROGRESS,   // Field officer started verification
        COMPLETED,     // All farms verified
        CANCELLED      // Assignment cancelled
    }
}

