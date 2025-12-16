package com.krushikranti.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.krushikranti.auth.dto.RegisterRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class RegistrationDataService {

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${otp.expiration}")
    private int registrationDataExpiration; // Use same expiration as OTP (5 minutes)

    /**
     * Store registration data temporarily in Redis
     * Key format: "registration:{phoneNumber}"
     */
    public void storeRegistrationData(String phoneNumber, RegisterRequest registerRequest) {
        try {
            String key = "registration:" + phoneNumber;
            String jsonData = objectMapper.writeValueAsString(registerRequest);
            redisTemplate.opsForValue().set(key, jsonData, registrationDataExpiration, TimeUnit.SECONDS);
            log.debug("Stored registration data for phone: {}", phoneNumber);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize registration data for phone: {}", phoneNumber, e);
            throw new RuntimeException("Failed to store registration data", e);
        }
    }

    /**
     * Retrieve registration data from Redis
     */
    public RegisterRequest getRegistrationData(String phoneNumber) {
        try {
            String key = "registration:" + phoneNumber;
            String jsonData = redisTemplate.opsForValue().get(key);
            
            if (jsonData == null) {
                log.debug("No registration data found for phone: {}", phoneNumber);
                return null;
            }
            
            RegisterRequest registerRequest = objectMapper.readValue(jsonData, RegisterRequest.class);
            log.debug("Retrieved registration data for phone: {}", phoneNumber);
            return registerRequest;
        } catch (JsonProcessingException e) {
            log.error("Failed to deserialize registration data for phone: {}", phoneNumber, e);
            throw new RuntimeException("Failed to retrieve registration data", e);
        }
    }

    /**
     * Delete registration data from Redis
     */
    public void deleteRegistrationData(String phoneNumber) {
        String key = "registration:" + phoneNumber;
        redisTemplate.delete(key);
        log.debug("Deleted registration data for phone: {}", phoneNumber);
    }
}

