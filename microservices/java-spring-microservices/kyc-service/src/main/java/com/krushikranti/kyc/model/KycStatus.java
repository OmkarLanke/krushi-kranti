package com.krushikranti.kyc.model;

/**
 * Enum representing KYC verification status.
 */
public enum KycStatus {
    PENDING,    // No verification done
    PARTIAL,    // Some verifications done
    VERIFIED,   // All verifications completed
    REJECTED    // Verification rejected
}

