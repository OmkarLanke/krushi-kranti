package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

/**
 * Request for Bank Account verification to Quick eKYC API.
 */
@Data
@Builder
public class BankVerificationRequest {
    
    @JsonProperty("key")
    private String key;
    
    @JsonProperty("id_number")
    private String idNumber;  // Bank Account Number
    
    @JsonProperty("ifsc")
    private String ifsc;  // IFSC Code
}

