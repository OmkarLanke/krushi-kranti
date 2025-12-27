package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.Map;

/**
 * Service for field officer profile operations (Field Officer facing).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FieldOfficerProfileService {

    private final FieldOfficerRepository fieldOfficerRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    /**
     * Get field officer profile by userId
     * Combines data from field_officers table and auth.users table
     */
    public Map<String, Object> getProfile(Long userId) {
        log.info("Fetching profile for field officer with userId: {}", userId);
        
        // Step 1: Get field officer from database
        FieldOfficer fieldOfficer = fieldOfficerRepository.findByUserId(userId)
                .orElseThrow(() -> {
                    log.error("Field officer not found for userId: {}", userId);
                    return new RuntimeException("Field officer profile not found. Please contact admin to create your profile.");
                });

        log.info("Found field officer: {} {} (ID: {})", 
                fieldOfficer.getFirstName(), fieldOfficer.getLastName(), fieldOfficer.getId());

        // Step 2: Get user details from auth-service (username, email, phoneNumber)
        Map<String, Object> userDetails = fetchUserDetails(userId);
        log.info("Fetched user details from auth-service: {}", userDetails);

        // Step 3: Combine both into a single response
        Map<String, Object> profile = new HashMap<>();
        
        // From field_officers table
        profile.put("fieldOfficerId", fieldOfficer.getId());
        profile.put("userId", fieldOfficer.getUserId());
        profile.put("firstName", fieldOfficer.getFirstName());
        profile.put("lastName", fieldOfficer.getLastName());
        profile.put("dateOfBirth", fieldOfficer.getDateOfBirth());
        profile.put("gender", fieldOfficer.getGender() != null ? fieldOfficer.getGender().name() : null);
        profile.put("alternatePhone", fieldOfficer.getAlternatePhone());
        profile.put("pincode", fieldOfficer.getPincode());
        profile.put("village", fieldOfficer.getVillage());
        profile.put("district", fieldOfficer.getDistrict());
        profile.put("taluka", fieldOfficer.getTaluka());
        profile.put("state", fieldOfficer.getState());
        profile.put("isActive", fieldOfficer.getIsActive());
        
        // From auth.users table
        String username = (String) userDetails.getOrDefault("username", "");
        String email = (String) userDetails.getOrDefault("email", "");
        String phoneNumber = (String) userDetails.getOrDefault("phoneNumber", "");
        
        profile.put("username", username != null ? username : "");
        profile.put("email", email != null ? email : "");
        profile.put("phoneNumber", phoneNumber != null ? phoneNumber : "");
        
        log.info("Profile built successfully for userId: {}", userId);
        log.info("Final profile email: {}, phoneNumber: {}, username: {}", 
                profile.get("email"), profile.get("phoneNumber"), profile.get("username"));
        return profile;
    }

    private Map<String, Object> fetchUserDetails(Long userId) {
        try {
            log.info("Calling auth-service to fetch user details for userId: {}", userId);
            log.info("Auth service URL: {}", authServiceUrl);
            
            Map<String, Object> response = webClientBuilder.build()
                    .get()
                    .uri(authServiceUrl + "/auth/user/{userId}", userId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
            
            log.info("Received response from auth-service: {}", response);
            
            if (response == null) {
                log.warn("Received null response from auth-service for userId: {}", userId);
                return new HashMap<>();
            }
            
            // The response is a UserInfo object with fields: id, username, email, phoneNumber, role, isVerified
            // Map it to our expected format
            Map<String, Object> userDetails = new HashMap<>();
            userDetails.put("username", response.getOrDefault("username", ""));
            userDetails.put("email", response.getOrDefault("email", ""));
            userDetails.put("phoneNumber", response.getOrDefault("phoneNumber", ""));
            
            log.info("Extracted user details: username={}, email={}, phoneNumber={}", 
                    userDetails.get("username"), userDetails.get("email"), userDetails.get("phoneNumber"));
            
            return userDetails;
        } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
            log.error("WebClient error fetching user details for userId {}: Status={}, Body={}", 
                    userId, e.getStatusCode(), e.getResponseBodyAsString());
            return new HashMap<>();
        } catch (Exception e) {
            log.error("Failed to fetch user details for userId {}: {}", userId, e.getMessage(), e);
            return new HashMap<>();
        }
    }
}

