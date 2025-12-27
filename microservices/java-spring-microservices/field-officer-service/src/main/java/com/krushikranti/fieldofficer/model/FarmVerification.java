package com.krushikranti.fieldofficer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Represents the verification of a farm by a field officer.
 * Stores verification status, feedback, and related information.
 */
@Entity
@Table(name = "farm_verifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmVerification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "verification_id")
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId; // Links to farmer-service farms table

    @Column(name = "field_officer_id", nullable = false)
    private Long fieldOfficerId;

    @Column(name = "verification_status", length = 20)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private VerificationStatus verificationStatus = VerificationStatus.PENDING;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "feedback", columnDefinition = "TEXT")
    private String feedback; // Feedback for rejection or notes

    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason; // Specific reason if rejected

    @Column(name = "latitude")
    private Double latitude; // GPS location where verification was done

    @Column(name = "longitude")
    private Double longitude;

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

    public enum VerificationStatus {
        PENDING,       // Not yet verified
        VERIFIED,      // Farm verified successfully
        REJECTED,      // Farm verification rejected
        IN_PROGRESS    // Verification in progress
    }
}

