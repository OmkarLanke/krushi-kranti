package com.krushikranti.farmer.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO for admin farmer detail view - full information
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminFarmerDetailDto {
    
    private Long farmerId;
    private Long userId;
    
    // Profile Information
    private ProfileInfo profile;
    
    // KYC Information
    private KycInfo kyc;
    
    // Subscription Information
    private SubscriptionInfo subscription;
    
    // Farms Information
    private List<FarmInfo> farms;

    // Crops Information
    private List<CropInfo> crops;
    
    // Assignment Information
    private AssignmentInfo assignment;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProfileInfo {
        private String firstName;
        private String lastName;
        private String fullName;
        private String username;
        private String email;
        private String phoneNumber;
        private String alternatePhone;
        private LocalDate dateOfBirth;
        private String gender;
        private String pincode;
        private String village;
        private String taluka;
        private String district;
        private String state;
        private Boolean isProfileComplete;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class KycInfo {
        private String status;  // PENDING, PARTIAL, VERIFIED
        private Boolean aadhaarVerified;
        private String aadhaarName;
        private String aadhaarNumberMasked;
        private LocalDateTime aadhaarVerifiedAt;
        private Boolean panVerified;
        private String panName;
        private String panNumberMasked;
        private LocalDateTime panVerifiedAt;
        private Boolean bankVerified;
        private String bankName;
        private String bankAccountHolderName;
        private String bankAccountMasked;
        private String bankIfsc;
        private LocalDateTime bankVerifiedAt;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubscriptionInfo {
        private Long subscriptionId;
        private String status;  // PENDING, ACTIVE, EXPIRED, CANCELLED
        private LocalDateTime startDate;
        private LocalDateTime endDate;
        private BigDecimal amount;
        private String paymentStatus;
        private String paymentTransactionId;
        private LocalDateTime paymentDate;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FarmInfo {
        private Long farmId;
        private String farmName;
        private String farmType;
        private BigDecimal totalAreaAcres;
        private String pincode;
        private String village;
        private String district;
        private String taluka;
        private String state;
        private String soilType;
        private String irrigationType;
        private String landOwnership;
        private String surveyNumber;
        private String landRegistrationNumber;
        private String pattaNumber;
        private BigDecimal estimatedLandValue;
        private String encumbranceStatus;
        private String encumbranceRemarks;
        private String landDocumentUrl;
        private String surveyMapUrl;
        private String registrationCertificateUrl;
        private Boolean isVerified;
        private Long verifiedByOfficerId;
        private String verifiedByOfficerName;
        private LocalDateTime verifiedAt;
        private String verificationRemarks;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CropInfo {
        private Long cropId;
        private Long farmId;
        private String farmName;
        private Long cropTypeId;
        private String cropTypeName;
        private Long cropNameId;
        private String cropName;
        private String cropDisplayName;
        private BigDecimal areaAcres;
        private LocalDate sowingDate;
        private LocalDate harvestingDate;
        private String cropStatus;
        private Boolean isActive;
        private LocalDateTime createdAt;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AssignmentInfo {
        private Long fieldOfficerId;
        private String fieldOfficerName;
        private String fieldOfficerPhone;
        private LocalDateTime assignedAt;
        private Long assignedByAdminId;
    }
}

