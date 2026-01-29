package com.krushikranti.subscription.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.util.Map;

/**
 * Client for communicating with Farmer Service.
 * Used to fetch farmer_id from user_id to ensure consistency across services.
 */
@Component
@Slf4j
public class FarmerServiceClient {

    private final WebClient webClient;

    public FarmerServiceClient(
            @Value("${services.farmer-service.url}") String farmerServiceUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(farmerServiceUrl)
                .build();
        log.info("FarmerServiceClient initialized with URL: {}", farmerServiceUrl);
    }

    /**
     * Fetch farmer_id from farmer-service using user_id.
     * Calls GET /farmer/profile/my-details with X-User-Id header.
     *
     * @param userId The authenticated user's ID
     * @return The farmer_id from farmer_db, or null if not found
     * @throws FarmerServiceException if there's an error communicating with farmer-service
     */
    public Long getFarmerIdByUserId(Long userId) {
        log.debug("Fetching farmer_id for userId: {}", userId);

        try {
            Map<String, Object> response = webClient.get()
                    .uri("/farmer/profile/my-details")
                    .header("X-User-Id", String.valueOf(userId))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(Duration.ofSeconds(10))
                    .block();

            if (response == null) {
                log.warn("Null response from farmer-service for userId: {}", userId);
                return null;
            }

            // Response format: { "message": "...", "data": { "id": 7, "userId": 9, ... } }
            Object dataObj = response.get("data");
            if (dataObj instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> data = (Map<String, Object>) dataObj;
                Object farmerId = data.get("id");
                
                if (farmerId instanceof Number) {
                    Long result = ((Number) farmerId).longValue();
                    log.info("Resolved farmer_id={} for userId={}", result, userId);
                    return result;
                }
            }

            log.warn("Could not extract farmer_id from response for userId: {}. Response: {}", userId, response);
            return null;

        } catch (WebClientResponseException e) {
            if (e.getStatusCode() == HttpStatus.NOT_FOUND) {
                log.warn("Farmer profile not found for userId: {}", userId);
                return null;
            }
            log.error("Error fetching farmer_id for userId: {}. Status: {}, Body: {}", 
                    userId, e.getStatusCode(), e.getResponseBodyAsString());
            throw new FarmerServiceException("Failed to fetch farmer profile: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error fetching farmer_id for userId: {}", userId, e);
            throw new FarmerServiceException("Failed to communicate with farmer-service: " + e.getMessage(), e);
        }
    }

    /**
     * Exception thrown when there's an error communicating with farmer-service.
     */
    public static class FarmerServiceException extends RuntimeException {
        public FarmerServiceException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
