package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * Response from Quick eKYC PAN Lite API.
 * Used for "Pan Verification API (NAME)" subscription.
 */
@Data
public class PanValidationResponse {
    
    @JsonProperty("data")
    private PanData data;
    
    @JsonProperty("status_code")
    private Integer statusCode;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("request_id")
    private Integer requestId;
    
    @JsonProperty("message")
    private String message;
    
    @Data
    public static class PanData {
        // PAN Lite response fields
        @JsonProperty("pan_number")
        private String panNumber;
        
        @JsonProperty("full_name")
        private String fullName;
        
        @JsonProperty("category")
        private String category;
        
        // For backward compatibility with PAN Validation endpoint
        @JsonProperty("is_valid")
        private Boolean isValid;
        
        /**
         * Check if PAN is valid based on response.
         * PAN Lite returns full_name when valid, PAN Validation returns is_valid flag.
         */
        public Boolean getIsValid() {
            // If is_valid is explicitly set, use it
            if (isValid != null) {
                return isValid;
            }
            // For PAN Lite, if full_name is present, PAN is valid
            return fullName != null && !fullName.isEmpty();
        }
    }
    
    public boolean isSuccess() {
        return "success".equalsIgnoreCase(status) && statusCode != null && statusCode == 200;
    }
    
    public String getRequestIdAsString() {
        return requestId != null ? String.valueOf(requestId) : null;
    }
}

