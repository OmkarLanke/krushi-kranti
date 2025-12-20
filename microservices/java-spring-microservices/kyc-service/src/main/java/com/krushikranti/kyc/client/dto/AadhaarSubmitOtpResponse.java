package com.krushikranti.kyc.client.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * Response from Quick eKYC Aadhaar Submit OTP API.
 * Contains full Aadhaar details on successful verification.
 */
@Data
public class AadhaarSubmitOtpResponse {
    
    @JsonProperty("data")
    private AadhaarData data;
    
    @JsonProperty("status_code")
    private Integer statusCode;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("request_id")
    private Object requestId;
    
    @Data
    public static class AadhaarData {
        @JsonProperty("client_id")
        private String clientId;
        
        @JsonProperty("full_name")
        private String fullName;
        
        @JsonProperty("aadhaar_number")
        private String aadhaarNumber;
        
        @JsonProperty("dob")
        private String dob;
        
        @JsonProperty("gender")
        private String gender;
        
        @JsonProperty("address")
        private AadhaarAddress address;
        
        @JsonProperty("face_status")
        private Boolean faceStatus;
        
        @JsonProperty("face_score")
        private Double faceScore;
        
        @JsonProperty("zip")
        private String zip;
        
        @JsonProperty("profile_image")
        private String profileImage;
        
        @JsonProperty("has_image")
        private Boolean hasImage;
        
        @JsonProperty("email_hash")
        private String emailHash;
        
        @JsonProperty("mobile_hash")
        private String mobileHash;
        
        @JsonProperty("raw_xml")
        private String rawXml;
        
        @JsonProperty("zip_data")
        private String zipData;
        
        @JsonProperty("care_of")
        private String careOf;
        
        @JsonProperty("share_code")
        private String shareCode;
        
        @JsonProperty("mobile_verified")
        private Boolean mobileVerified;
        
        @JsonProperty("reference_id")
        private String referenceId;
        
        @JsonProperty("aadhaar_pdf")
        private String aadhaarPdf;
    }
    
    @Data
    public static class AadhaarAddress {
        @JsonProperty("country")
        private String country;
        
        @JsonProperty("dist")
        private String dist;
        
        @JsonProperty("state")
        private String state;
        
        @JsonProperty("po")
        private String po;
        
        @JsonProperty("loc")
        private String loc;
        
        @JsonProperty("vtc")
        private String vtc;
        
        @JsonProperty("subdist")
        private String subdist;
        
        @JsonProperty("street")
        private String street;
        
        @JsonProperty("house")
        private String house;
        
        @JsonProperty("landmark")
        private String landmark;
        
        public String getFullAddress() {
            StringBuilder sb = new StringBuilder();
            if (house != null && !house.isEmpty()) sb.append(house).append(", ");
            if (street != null && !street.isEmpty()) sb.append(street).append(", ");
            if (landmark != null && !landmark.isEmpty()) sb.append(landmark).append(", ");
            if (loc != null && !loc.isEmpty()) sb.append(loc).append(", ");
            if (vtc != null && !vtc.isEmpty()) sb.append(vtc).append(", ");
            if (po != null && !po.isEmpty()) sb.append("PO: ").append(po).append(", ");
            if (subdist != null && !subdist.isEmpty()) sb.append(subdist).append(", ");
            if (dist != null && !dist.isEmpty()) sb.append(dist).append(", ");
            if (state != null && !state.isEmpty()) sb.append(state).append(", ");
            if (country != null && !country.isEmpty()) sb.append(country);
            return sb.toString().replaceAll(", $", "");
        }
    }
    
    public boolean isSuccess() {
        return "success".equalsIgnoreCase(status) && statusCode != null && statusCode == 200;
    }
}

