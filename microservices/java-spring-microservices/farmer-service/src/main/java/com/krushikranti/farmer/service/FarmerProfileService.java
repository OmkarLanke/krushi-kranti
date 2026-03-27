package com.krushikranti.farmer.service;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.MyDetailsRequest;
import com.krushikranti.farmer.dto.MyDetailsResponse;
import com.krushikranti.farmer.model.Farmer;
import com.krushikranti.farmer.repository.FarmerRepository;
import com.krushikranti.auth.grpc.UserInfoResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Service for managing farmer profile "My Details" section.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmerProfileService {

    private final FarmerRepository farmerRepository;
    private final AuthServiceClient authServiceClient;
    private final PincodeService pincodeService;
    private final AdminFarmerService adminFarmerService;

    /**
     * Get farmer's "My Details" profile.
     * Fetches email and phone from Auth Service via gRPC.
     * ADMIN users are not allowed to access farmer profiles.
     * 
     * @param userId The user ID from gateway header
     * @return MyDetailsResponse with all profile information
     * @throws IllegalArgumentException if user is ADMIN
     */
    @Transactional(readOnly = true)
    public MyDetailsResponse getMyDetails(Long userId) {
        // Get user info (email, phone, role) from Auth Service via gRPC
        String email = "";
        String phoneNumber = "";
        boolean isAdmin = false;
        try {
            UserInfoResponse userInfo = authServiceClient.getUserById(String.valueOf(userId));
            email = userInfo.getEmail();
            phoneNumber = userInfo.getPhoneNumber();
            // Check if user has ADMIN role
            isAdmin = userInfo.getRolesList().contains("ADMIN");
        } catch (Exception e) {
            log.warn("Failed to retrieve user info from Auth Service for userId {}: {}. Continuing with empty email/phone.", userId, e.getMessage());
        }
        
        // ADMIN users should not have farmer profiles
        if (isAdmin) {
            log.warn("ADMIN user (userId: {}) attempted to access farmer profile. This is not allowed.", userId);
            throw new IllegalArgumentException("ADMIN users cannot access farmer profiles. This endpoint is for FARMER role only.");
        }
        
        // Get farmer profile from database
        Optional<Farmer> farmerOpt = farmerRepository.findByUserId(userId);
        
        if (farmerOpt.isEmpty()) {
            // Return response with only auth service data (profile not created yet)
            return MyDetailsResponse.builder()
                    .userId(userId)
                    .email(email)
                    .phoneNumber(phoneNumber)
                    .build();
        }

        Farmer farmer = farmerOpt.get();
        
        return MyDetailsResponse.builder()
                .id(farmer.getId())
                .userId(farmer.getUserId())
                .firstName(farmer.getFirstName())
                .lastName(farmer.getLastName())
                .dateOfBirth(farmer.getDateOfBirth())
                .gender(farmer.getGender())
                .email(email)
                .phoneNumber(phoneNumber)
                .alternatePhone(farmer.getAlternatePhone())
                .pincode(farmer.getPincode())
                .village(farmer.getVillage())
                .district(farmer.getDistrict())
                .taluka(farmer.getTaluka())
                .state(farmer.getState())
                .build();
    }

    /**
     * Create or update farmer's "My Details" profile.
     * Validates pincode and fetches address details.
     * ADMIN users are not allowed to create farmer profiles.
     * 
     * @param userId The user ID from gateway header
     * @param request The profile data to save
     * @return Updated MyDetailsResponse
     * @throws IllegalArgumentException if user is ADMIN
     */
    @Transactional
    public MyDetailsResponse saveMyDetails(Long userId, MyDetailsRequest request) {
        // Get user info from Auth Service to check role
        String email = "";
        String phoneNumber = "";
        boolean isAdmin = false;
        try {
            UserInfoResponse userInfo = authServiceClient.getUserById(String.valueOf(userId));
            email = userInfo.getEmail();
            phoneNumber = userInfo.getPhoneNumber();
            // Check if user has ADMIN role
            isAdmin = userInfo.getRolesList().contains("ADMIN");
        } catch (Exception e) {
            log.warn("Failed to retrieve user info from Auth Service for userId {}: {}. Profile will be saved without email/phone.", userId, e.getMessage());
        }
        
        // ADMIN users should not create farmer profiles
        if (isAdmin) {
            log.warn("ADMIN user (userId: {}) attempted to create farmer profile. This is not allowed.", userId);
            throw new IllegalArgumentException("ADMIN users cannot create farmer profiles. This endpoint is for FARMER role only.");
        }
        
        // Validate pincode and get address details
        AddressLookupResponse addressLookup = pincodeService.getAddressByPincode(request.getPincode());
        
        // Verify that the selected village exists for this pincode
        if (!addressLookup.getVillages().contains(request.getVillage())) {
            throw new IllegalArgumentException("Selected village does not exist for the given pincode");
        }

        // Check if farmer profile already exists
        Optional<Farmer> farmerOpt = farmerRepository.findByUserId(userId);
        
        Farmer farmer;
        if (farmerOpt.isPresent()) {
            // Update existing profile
            farmer = farmerOpt.get();
            farmer.setFirstName(request.getFirstName());
            farmer.setLastName(request.getLastName());
            farmer.setDateOfBirth(request.getDateOfBirth());
            farmer.setGender(request.getGender());
            farmer.setAlternatePhone(request.getAlternatePhone());
            farmer.setPincode(request.getPincode());
            farmer.setVillage(request.getVillage());
            farmer.setDistrict(addressLookup.getDistrict());
            farmer.setTaluka(addressLookup.getTaluka());
            farmer.setState(addressLookup.getState());
            log.info("Updated farmer profile for userId: {}", userId);
        } else {
            // Create new profile
            farmer = Farmer.builder()
                    .userId(userId)
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .dateOfBirth(request.getDateOfBirth())
                    .gender(request.getGender())
                    .alternatePhone(request.getAlternatePhone())
                    .pincode(request.getPincode())
                    .village(request.getVillage())
                    .district(addressLookup.getDistrict())
                    .taluka(addressLookup.getTaluka())
                    .state(addressLookup.getState())
                    .build();
            log.info("Created new farmer profile for userId: {}", userId);
        }

        farmer = farmerRepository.save(farmer);
        adminFarmerService.invalidateAdminFarmerListCache();

        // Build response with auth service data (email/phone may be empty if gRPC call failed)
        return MyDetailsResponse.builder()
                .id(farmer.getId())
                .userId(farmer.getUserId())
                .firstName(farmer.getFirstName())
                .lastName(farmer.getLastName())
                .dateOfBirth(farmer.getDateOfBirth())
                .gender(farmer.getGender())
                .email(email)
                .phoneNumber(phoneNumber)
                .alternatePhone(farmer.getAlternatePhone())
                .pincode(farmer.getPincode())
                .village(farmer.getVillage())
                .district(farmer.getDistrict())
                .taluka(farmer.getTaluka())
                .state(farmer.getState())
                .build();
    }
}

