package com.krushikranti.fieldofficer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "field_officers")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FieldOfficer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "field_officer_id")
    private Long id;

    @Column(name = "user_id", unique = true, nullable = false)
    private Long userId; // Links to auth.users.id

    @Column(name = "first_name", length = 100)
    private String firstName;

    @Column(name = "last_name", length = 100)
    private String lastName;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "gender", length = 10)
    @Enumerated(EnumType.STRING)
    private Gender gender;

    @Column(name = "alternate_phone", length = 15)
    private String alternatePhone;

    @Column(name = "pincode", length = 6)
    private String pincode;

    @Column(name = "village", length = 200)
    private String village;

    @Column(name = "district", length = 100)
    private String district;

    @Column(name = "taluka", length = 100)
    private String taluka;

    @Column(name = "state", length = 100)
    private String state;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

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

    public enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
}

