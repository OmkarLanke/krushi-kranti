package com.krushikranti.kyc.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * Request DTO for Bank Account verification.
 */
@Data
public class BankVerifyRequest {
    
    @NotBlank(message = "Account number is required")
    @Pattern(regexp = "^[0-9]{9,18}$", 
             message = "Invalid account number. Must be 9-18 digits")
    private String accountNumber;
    
    @NotBlank(message = "IFSC code is required")
    @Pattern(regexp = "^[A-Z]{4}0[A-Z0-9]{6}$", 
             message = "Invalid IFSC format. Must be in format XXXX0XXXXXX")
    private String ifscCode;
}

