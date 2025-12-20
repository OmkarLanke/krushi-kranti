package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * Response from Quick eKYC Bank Verification API.
 */
@Data
public class BankVerificationResponse {
    
    @JsonProperty("data")
    private BankData data;
    
    @JsonProperty("status_code")
    private Integer statusCode;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("request_id")
    private Object requestId;
    
    @Data
    public static class BankData {
        @JsonProperty("account_exists")
        private Boolean accountExists;
        
        @JsonProperty("upi_id")
        private String upiId;
        
        @JsonProperty("full_name")
        private String fullName;
        
        @JsonProperty("remarks")
        private String remarks;
        
        @JsonProperty("ifsc_details")
        private IfscDetails ifscDetails;
    }
    
    @Data
    public static class IfscDetails {
        @JsonProperty("bank")
        private String bank;
        
        @JsonProperty("branch")
        private String branch;
        
        @JsonProperty("address")
        private String address;
        
        @JsonProperty("city")
        private String city;
        
        @JsonProperty("district")
        private String district;
        
        @JsonProperty("state")
        private String state;
    }
    
    public boolean isSuccess() {
        return "success".equalsIgnoreCase(status) && statusCode != null && statusCode == 200;
    }
}

