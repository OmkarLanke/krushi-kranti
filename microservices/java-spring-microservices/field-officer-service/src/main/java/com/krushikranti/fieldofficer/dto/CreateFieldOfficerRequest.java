package com.krushikranti.fieldofficer.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Request DTO for creating a new field officer by admin
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateFieldOfficerRequest {
    
    // Personal Information
    @NotBlank(message = "First name is required")
    @Size(max = 100, message = "First name must not exceed 100 characters")
    private String firstName;
    
    @NotBlank(message = "Last name is required")
    @Size(max = 100, message = "Last name must not exceed 100 characters")
    private String lastName;
    
    private LocalDate dateOfBirth;
    
    @NotNull(message = "Gender is required")
    private String gender; // MALE, FEMALE, OTHER
    
    // Contact Information (Admin Sets)
    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[0-9]{10}$", message = "Phone number must be 10 digits")
    private String phoneNumber;
    
    @Pattern(regexp = "^[0-9]{10}$", message = "Alternate phone must be 10 digits")
    private String alternatePhone;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    @Size(max = 100, message = "Email must not exceed 100 characters")
    private String email;
    
    // Address Information
    @NotBlank(message = "Pincode is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "Pincode must be 6 digits")
    private String pincode;
    
    @NotBlank(message = "Village is required")
    @Size(max = 200, message = "Village must not exceed 200 characters")
    private String village;
    
    private String district;
    private String taluka;
    private String state;
    
    // Credentials (Admin Assigns)
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;
    
    // Additional
    @Builder.Default
    private Boolean isActive = true;
}

