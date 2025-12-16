package com.krushikranti.farmer.controller;

import com.krushikranti.farmer.dto.AddressLookupResponse;
import com.krushikranti.farmer.dto.ApiResponse;
import com.krushikranti.farmer.dto.MyDetailsRequest;
import com.krushikranti.farmer.dto.MyDetailsResponse;
import com.krushikranti.farmer.service.FarmerProfileService;
import com.krushikranti.farmer.service.PincodeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for Farmer Service.
 * All endpoints are protected and require JWT token via API Gateway.
 */
@RestController
@RequestMapping("/farmer")
@RequiredArgsConstructor
@Slf4j
public class FarmerController {

    private final FarmerProfileService farmerProfileService;
    private final PincodeService pincodeService;

    /**
     * Get farmer's "My Details" profile.
     * Email and phone are fetched from Auth Service via gRPC.
     */
    @GetMapping("/profile/my-details")
    public ResponseEntity<ApiResponse<MyDetailsResponse>> getMyDetails(
            @RequestHeader("X-User-Id") String userIdHeader) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Getting my details for userId: {}", userId);
        
        MyDetailsResponse response = farmerProfileService.getMyDetails(userId);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farmer profile retrieved successfully",
                response));
    }

    /**
     * Create or update farmer's "My Details" profile.
     */
    @PutMapping("/profile/my-details")
    public ResponseEntity<ApiResponse<MyDetailsResponse>> saveMyDetails(
            @RequestHeader("X-User-Id") String userIdHeader,
            @Valid @RequestBody MyDetailsRequest request) {
        
        Long userId = Long.parseLong(userIdHeader);
        log.debug("Saving my details for userId: {}", userId);
        
        MyDetailsResponse response = farmerProfileService.saveMyDetails(userId, request);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Farmer profile saved successfully",
                response));
    }

    /**
     * Lookup address details by pincode.
     * Returns district, taluka, state, and list of villages.
     */
    @GetMapping("/profile/address/lookup")
    public ResponseEntity<ApiResponse<AddressLookupResponse>> lookupAddress(
            @RequestParam("pincode") String pincode) {
        
        log.debug("Looking up address for pincode: {}", pincode);
        
        AddressLookupResponse response = pincodeService.getAddressByPincode(pincode);
        
        return ResponseEntity.ok(new ApiResponse<>(
                "Address lookup successful",
                response));
    }

    /**
     * Health check endpoint.
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Farmer Service is running");
    }
}

