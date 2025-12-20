package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

/**
 * Base request for Quick eKYC API calls.
 */
@Data
@Builder
public class QuickEkycRequest {
    
    @JsonProperty("key")
    private String key;
    
    @JsonProperty("id_number")
    private String idNumber;
}

