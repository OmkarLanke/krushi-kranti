package com.krushikranti.fieldofficer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Represents photos uploaded during farm verification.
 * Photos are stored in S3, this table stores metadata and URLs.
 */
@Entity
@Table(name = "verification_photos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerificationPhoto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "photo_id")
    private Long id;

    @Column(name = "verification_id", nullable = false)
    private Long verificationId; // Links to farm_verifications

    @Column(name = "photo_url", nullable = false, length = 500)
    private String photoUrl; // S3 URL or signed URL

    @Column(name = "photo_type", length = 50)
    @Enumerated(EnumType.STRING)
    private PhotoType photoType;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "uploaded_at", updatable = false)
    private LocalDateTime uploadedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        uploadedAt = LocalDateTime.now();
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum PhotoType {
        FARM_OVERVIEW,      // Overall farm view
        BOUNDARY,           // Farm boundaries
        CROP,               // Crop photos
        DOCUMENT,           // Land documents
        OTHER               // Other photos
    }
}

