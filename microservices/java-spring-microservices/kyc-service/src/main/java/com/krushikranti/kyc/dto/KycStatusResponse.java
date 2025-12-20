package com.krushikranti.kyc.dto;

import com.krushikranti.kyc.model.KycStatus;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Response DTO for KYC status.
 */
@Data
@Builder
public class KycStatusResponse {
    
    private Long userId;
    private KycStatus kycStatus;
    
    // Aadhaar
    private Boolean aadhaarVerified;
    private String aadhaarNumberMasked;
    private String aadhaarName;
    private LocalDateTime aadhaarVerifiedAt;
    
    // PAN
    private Boolean panVerified;
    private String panNumberMasked;
    private String panName;
    private LocalDateTime panVerifiedAt;
    
    // Bank
    private Boolean bankVerified;
    private String bankAccountMasked;
    private String bankIfsc;
    private String bankName;
    private String bankAccountHolderName;
    private LocalDateTime bankVerifiedAt;
}

