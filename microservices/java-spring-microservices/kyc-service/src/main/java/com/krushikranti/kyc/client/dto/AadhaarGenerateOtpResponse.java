package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * Response from Quick eKYC Aadhaar Generate OTP API.
 */
@Data
public class AadhaarGenerateOtpResponse {
    
    @JsonProperty("data")
    private AadhaarOtpData data;
    
    @JsonProperty("status_code")
    private Integer statusCode;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("request_id")
    private Object requestId;  // Can be Integer or String
    
    @Data
    public static class AadhaarOtpData {
        @JsonProperty("otp_sent")
        private Boolean otpSent;
        
        @JsonProperty("if_number")
        private Boolean ifNumber;
        
        @JsonProperty("valid_aadhaar")
        private Boolean validAadhaar;
        
        @JsonProperty("client_id")
        private String clientId;
    }
    
    public boolean isSuccess() {
        return "success".equalsIgnoreCase(status) && statusCode != null && statusCode == 200;
    }
    
    public String getRequestIdAsString() {
        return requestId != null ? String.valueOf(requestId) : null;
    }
}

