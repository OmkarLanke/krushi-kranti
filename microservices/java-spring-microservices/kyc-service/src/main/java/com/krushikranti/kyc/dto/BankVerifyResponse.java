package com.krushikranti.kyc.dto;

import lombok.Builder;
import lombok.Data;

/**
 * Response DTO for Bank Account verification.
 */
@Data
@Builder
public class BankVerifyResponse {
    
    private Boolean verified;
    private String accountNumberMasked;
    private String ifscCode;
    private String accountHolderName;
    private String bankName;
    private String message;
}

