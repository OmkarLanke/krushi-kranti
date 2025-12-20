package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

/**
 * Request for Aadhaar OTP submission to Quick eKYC API.
 */
@Data
@Builder
public class AadhaarSubmitOtpRequest {
    
    @JsonProperty("key")
    private String key;
    
    @JsonProperty("request_id")
    private String requestId;
    
    @JsonProperty("otp")
    private String otp;
}

