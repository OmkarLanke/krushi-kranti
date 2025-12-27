package com.krushikranti.fieldofficer.service;

import com.krushikranti.fieldofficer.dto.CreateFieldOfficerRequest;
import com.krushikranti.fieldofficer.dto.FieldOfficerSummaryDto;
import com.krushikranti.fieldofficer.model.FieldOfficer;
import com.krushikranti.fieldofficer.repository.FieldOfficerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service for field officer management operations (Admin).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FieldOfficerService {

    private final FieldOfficerRepository fieldOfficerRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${services.auth-service.url:http://localhost:4005}")
    private String authServiceUrl;

    /**
     * Create a new field officer
     * 1. Create user in auth-service
     * 2. Create field officer profile
     */
    @Transactional
    public FieldOfficerSummaryDto createFieldOfficer(CreateFieldOfficerRequest request) {
        // Step 1: Create user in auth-service
        Long userId = createUserInAuthService(request);
        
        // Step 2: Create field officer profile
        FieldOfficer fieldOfficer = FieldOfficer.builder()
                .userId(userId)
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .dateOfBirth(request.getDateOfBirth())
                .gender(FieldOfficer.Gender.valueOf(request.getGender()))
                .alternatePhone(request.getAlternatePhone())
                .pincode(request.getPincode())
                .village(request.getVillage())
                .district(request.getDistrict())
                .taluka(request.getTaluka())
                .state(request.getState())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();
        
        FieldOfficer saved = fieldOfficerRepository.save(fieldOfficer);
        log.info("Field officer created: {} (ID: {})", saved.getId(), userId);
        
        // Fetch user details to build summary
        Map<String, Object> userDetails = fetchUserDetails(userId);
        
        return buildSummaryDto(saved, userDetails);
    }

    /**
     * Get paginated list of all field officers
     */
    public Map<String, Object> getAllFieldOfficers(int page, int size, String search, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        
        Page<FieldOfficer> fieldOfficerPage;
        
        if (search != null && !search.trim().isEmpty()) {
            fieldOfficerPage = fieldOfficerRepository.searchFieldOfficers(search.trim(), pageable);
        } else if (isActive != null) {
            fieldOfficerPage = fieldOfficerRepository.findByIsActive(isActive, pageable);
        } else {
            fieldOfficerPage = fieldOfficerRepository.findAll(pageable);
        }

        List<Long> userIds = fieldOfficerPage.getContent().stream()
                .map(FieldOfficer::getUserId)
                .collect(Collectors.toList());

        // Fetch user details (username, email, phone) from auth service
        Map<Long, Map<String, Object>> userMap = fetchUserDetailsBatch(userIds);

        List<FieldOfficerSummaryDto> summaries = fieldOfficerPage.getContent().stream()
                .map(fo -> {
                    Map<String, Object> userDetails = userMap.getOrDefault(fo.getUserId(), new HashMap<>());
                    return buildSummaryDto(fo, userDetails);
                })
                .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("fieldOfficers", summaries);
        response.put("currentPage", fieldOfficerPage.getNumber());
        response.put("totalPages", fieldOfficerPage.getTotalPages());
        response.put("totalElements", fieldOfficerPage.getTotalElements());
        response.put("pageSize", fieldOfficerPage.getSize());
        response.put("hasNext", fieldOfficerPage.hasNext());
        response.put("hasPrevious", fieldOfficerPage.hasPrevious());

        return response;
    }

    // ==================== Helper Methods ====================

    private Long createUserInAuthService(CreateFieldOfficerRequest request) {
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("username", request.getUsername());
            requestBody.put("email", request.getEmail());
            requestBody.put("phoneNumber", request.getPhoneNumber());
            requestBody.put("password", request.getPassword());
            requestBody.put("role", "FIELD_OFFICER");

            log.info("Creating user in auth-service: username={}, email={}, phone={}", 
                request.getUsername(), request.getEmail(), request.getPhoneNumber());

            Map<String, Object> response;
            try {
                response = webClientBuilder.build()
                        .post()
                        .uri(authServiceUrl + "/auth/admin/create-user")
                        .bodyValue(requestBody)
                        .retrieve()
                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                        .block();
            } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
                log.error("Error from auth-service ({}): {}", e.getStatusCode(), e.getResponseBodyAsString());
                throw new RuntimeException(
                    e.getStatusCode() + " Bad Request from POST " + 
                    authServiceUrl + "/auth/admin/create-user: " + e.getResponseBodyAsString(), e);
            }

            if (response == null) {
                throw new RuntimeException("No response from auth-service");
            }

            // The response is a UserInfo object with id field
            Object idObj = response.get("id");
            if (idObj == null) {
                log.error("Response from auth-service: {}", response);
                throw new RuntimeException("User ID not found in response from auth-service");
            }

            Long userId;
            if (idObj instanceof Number) {
                userId = ((Number) idObj).longValue();
            } else {
                userId = Long.parseLong(idObj.toString());
            }

            log.info("User created successfully in auth-service with ID: {}", userId);
            return userId;
        } catch (RuntimeException e) {
            // Re-throw RuntimeException as-is
            throw e;
        } catch (Exception e) {
            log.error("Error creating user in auth-service: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to create user: " + e.getMessage(), e);
        }
    }

    private Map<String, Object> fetchUserDetails(Long userId) {
        try {
            return webClientBuilder.build()
                    .get()
                    .uri(authServiceUrl + "/auth/user/{userId}", userId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();
        } catch (Exception e) {
            log.warn("Failed to fetch user details for userId {}: {}", userId, e.getMessage());
            return new HashMap<>();
        }
    }

    private Map<Long, Map<String, Object>> fetchUserDetailsBatch(List<Long> userIds) {
        Map<Long, Map<String, Object>> userMap = new HashMap<>();
        
        for (Long userId : userIds) {
            try {
                Map<String, Object> userDetails = fetchUserDetails(userId);
                userMap.put(userId, userDetails);
            } catch (Exception e) {
                log.warn("Failed to fetch user details for userId {}: {}", userId, e.getMessage());
            }
        }
        
        return userMap;
    }

    private FieldOfficerSummaryDto buildSummaryDto(FieldOfficer fieldOfficer, Map<String, Object> userDetails) {
        String fullName = buildFullName(fieldOfficer.getFirstName(), fieldOfficer.getLastName());
        
        return FieldOfficerSummaryDto.builder()
                .fieldOfficerId(fieldOfficer.getId())
                .userId(fieldOfficer.getUserId())
                .fullName(fullName)
                .username((String) userDetails.getOrDefault("username", ""))
                .phoneNumber((String) userDetails.getOrDefault("phoneNumber", ""))
                .email((String) userDetails.getOrDefault("email", ""))
                .village(fieldOfficer.getVillage())
                .district(fieldOfficer.getDistrict())
                .state(fieldOfficer.getState())
                .isActive(fieldOfficer.getIsActive())
                .createdAt(fieldOfficer.getCreatedAt())
                .lastUpdatedAt(fieldOfficer.getUpdatedAt())
                .build();
    }

    private String buildFullName(String firstName, String lastName) {
        String fn = firstName != null ? firstName : "";
        String ln = lastName != null ? lastName : "";
        return (fn + " " + ln).trim();
    }
}

