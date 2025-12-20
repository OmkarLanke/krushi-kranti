package com.krushikranti.kyc.dto;

import lombok.Builder;
import lombok.Data;

/**
 * Response DTO for PAN verification.
 */
@Data
@Builder
public class PanVerifyResponse {
    
    private Boolean verified;
    private String panNumberMasked;
    private String name;
    private String message;
}

