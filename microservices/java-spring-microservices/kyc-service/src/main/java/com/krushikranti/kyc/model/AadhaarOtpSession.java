package com.krushikranti.kyc.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Entity for storing Aadhaar OTP sessions.
 */
@Entity
@Table(name = "aadhaar_otp_sessions")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AadhaarOtpSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "aadhaar_number_hash", nullable = false, length = 64)
    private String aadhaarNumberHash;

    @Column(name = "client_id", length = 100)
    private String clientId;

    @Column(name = "request_id", nullable = false, length = 100)
    private String requestId;

    @Column(name = "otp_sent", nullable = false)
    @Builder.Default
    private Boolean otpSent = false;

    @Column(name = "otp_verified", nullable = false)
    @Builder.Default
    private Boolean otpVerified = false;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }
}

