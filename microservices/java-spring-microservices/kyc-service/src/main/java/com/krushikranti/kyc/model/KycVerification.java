package com.krushikranti.kyc.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entity representing KYC verification status for a user.
 */
@Entity
@Table(name = "kyc_verifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KycVerification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    @Builder.Default
    private KycStatus kycStatus = KycStatus.PENDING;

    // Aadhaar Verification
    @Column(name = "aadhaar_verified", nullable = false)
    @Builder.Default
    private Boolean aadhaarVerified = false;

    @Column(name = "aadhaar_number_masked", length = 16)
    private String aadhaarNumberMasked;

    @Column(name = "aadhaar_name")
    private String aadhaarName;

    @Column(name = "aadhaar_dob")
    private LocalDate aadhaarDob;

    @Column(name = "aadhaar_gender", length = 10)
    private String aadhaarGender;

    @Column(name = "aadhaar_address", columnDefinition = "TEXT")
    private String aadhaarAddress;

    @Column(name = "aadhaar_verified_at")
    private LocalDateTime aadhaarVerifiedAt;

    // PAN Verification
    @Column(name = "pan_verified", nullable = false)
    @Builder.Default
    private Boolean panVerified = false;

    @Column(name = "pan_number_masked", length = 10)
    private String panNumberMasked;

    @Column(name = "pan_name")
    private String panName;

    @Column(name = "pan_verified_at")
    private LocalDateTime panVerifiedAt;

    // Bank Account Verification
    @Column(name = "bank_verified", nullable = false)
    @Builder.Default
    private Boolean bankVerified = false;

    @Column(name = "bank_account_masked", length = 20)
    private String bankAccountMasked;

    @Column(name = "bank_ifsc", length = 11)
    private String bankIfsc;

    @Column(name = "bank_name")
    private String bankName;

    @Column(name = "bank_account_holder_name")
    private String bankAccountHolderName;

    @Column(name = "bank_verified_at")
    private LocalDateTime bankVerifiedAt;

    // Audit fields
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
        updateKycStatus();
    }

    @PostLoad
    @PostPersist
    protected void updateKycStatus() {
        if (Boolean.TRUE.equals(aadhaarVerified) && 
            Boolean.TRUE.equals(panVerified) && 
            Boolean.TRUE.equals(bankVerified)) {
            this.kycStatus = KycStatus.VERIFIED;
        } else if (Boolean.TRUE.equals(aadhaarVerified) || 
                   Boolean.TRUE.equals(panVerified) || 
                   Boolean.TRUE.equals(bankVerified)) {
            this.kycStatus = KycStatus.PARTIAL;
        } else {
            this.kycStatus = KycStatus.PENDING;
        }
    }
}

