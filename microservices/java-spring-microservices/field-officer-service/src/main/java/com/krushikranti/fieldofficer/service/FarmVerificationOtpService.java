package com.krushikranti.fieldofficer.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.TimeUnit;

/**
 * Service for managing OTP for farm verification.
 * OTP is stored in Redis with key: farm_verification_otp:{farmId}:{farmerUserId}
 */
@Service
@Slf4j
public class FarmVerificationOtpService {

    private final RedisTemplate<String, String> redisTemplate;

    @Value("${farm-verification.otp.expiration:600}")
    private int otpExpiration; // Default 10 minutes

    @Value("${farm-verification.otp.length:6}")
    private int otpLength; // Default 6 digits

    @Value("${farm-verification.otp.max-requests-per-hour:3}")
    private int maxRequestsPerHour;

    public FarmVerificationOtpService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * Generate OTP for farm verification.
     * 
     * @param farmId The farm ID being verified
     * @param farmerUserId The farmer's user ID (owner of the farm)
     * @param fieldOfficerUserId The field officer's user ID (for audit)
     * @return Generated OTP
     */
    public String generateOtp(Long farmId, Long farmerUserId, Long fieldOfficerUserId) {
        // Check rate limiting
        String rateLimitKey = "farm_verification_otp_rate_limit:{farmId}:{fieldOfficerUserId}"
                .replace("{farmId}", String.valueOf(farmId))
                .replace("{fieldOfficerUserId}", String.valueOf(fieldOfficerUserId));
        
        String requestCount = redisTemplate.opsForValue().get(rateLimitKey);
        if (requestCount != null) {
            int count = Integer.parseInt(requestCount);
            if (count >= maxRequestsPerHour) {
                throw new IllegalStateException(
                        "Maximum OTP requests exceeded. Please wait before requesting again.");
            }
        }

        // Generate OTP
        String otp = generateRandomOtp();
        
        // Store OTP with key: farm_verification_otp:{farmId}:{farmerUserId}
        String otpKey = "farm_verification_otp:{farmId}:{farmerUserId}"
                .replace("{farmId}", String.valueOf(farmId))
                .replace("{farmerUserId}", String.valueOf(farmerUserId));
        
        // Store OTP with metadata (field officer ID for audit)
        String otpValue = otp + ":" + fieldOfficerUserId;
        redisTemplate.opsForValue().set(otpKey, otpValue, otpExpiration, TimeUnit.SECONDS);
        
        // Update rate limit counter
        String currentCount = redisTemplate.opsForValue().get(rateLimitKey);
        int newCount = (currentCount == null) ? 1 : Integer.parseInt(currentCount) + 1;
        redisTemplate.opsForValue().set(rateLimitKey, String.valueOf(newCount), 1, TimeUnit.HOURS);
        
        log.info("Generated OTP for farm verification - Farm ID: {}, Farmer User ID: {}, Field Officer User ID: {}", 
                farmId, farmerUserId, fieldOfficerUserId);
        
        return otp;
    }

    /**
     * Validate OTP for farm verification.
     * 
     * @param farmId The farm ID being verified
     * @param farmerUserId The farmer's user ID
     * @param otp The OTP to validate
     * @return true if OTP is valid, false otherwise
     */
    public boolean validateOtp(Long farmId, Long farmerUserId, String otp) {
        String otpKey = "farm_verification_otp:{farmId}:{farmerUserId}"
                .replace("{farmId}", String.valueOf(farmId))
                .replace("{farmerUserId}", String.valueOf(farmerUserId));
        
        String storedValue = redisTemplate.opsForValue().get(otpKey);
        
        if (storedValue == null) {
            log.warn("OTP validation failed - OTP not found or expired. Farm ID: {}, Farmer User ID: {}", 
                    farmId, farmerUserId);
            return false;
        }
        
        // Extract OTP from stored value (format: otp:fieldOfficerUserId)
        String storedOtp = storedValue.split(":")[0];
        
        if (storedOtp.equals(otp)) {
            // OTP is valid - delete it (one-time use)
            redisTemplate.delete(otpKey);
            
            // Mark as validated (store validation status for 1 hour)
            String validationKey = "farm_verification_otp_validated:{farmId}:{farmerUserId}"
                    .replace("{farmId}", String.valueOf(farmId))
                    .replace("{farmerUserId}", String.valueOf(farmerUserId));
            redisTemplate.opsForValue().set(validationKey, "true", 1, TimeUnit.HOURS);
            
            log.info("OTP validated successfully - Farm ID: {}, Farmer User ID: {}", farmId, farmerUserId);
            return true;
        }
        
        log.warn("OTP validation failed - Invalid OTP. Farm ID: {}, Farmer User ID: {}", farmId, farmerUserId);
        return false;
    }

    /**
     * Check if OTP has been validated for this farm verification.
     * 
     * @param farmId The farm ID
     * @param farmerUserId The farmer's user ID
     * @return true if OTP was validated, false otherwise
     */
    public boolean isOtpValidated(Long farmId, Long farmerUserId) {
        String validationKey = "farm_verification_otp_validated:{farmId}:{farmerUserId}"
                .replace("{farmId}", String.valueOf(farmId))
                .replace("{farmerUserId}", String.valueOf(farmerUserId));
        
        String validated = redisTemplate.opsForValue().get(validationKey);
        return "true".equals(validated);
    }

    /**
     * Clear OTP validation status (useful for testing or reset)
     */
    public void clearOtpValidation(Long farmId, Long farmerUserId) {
        String validationKey = "farm_verification_otp_validated:{farmId}:{farmerUserId}"
                .replace("{farmId}", String.valueOf(farmId))
                .replace("{farmerUserId}", String.valueOf(farmerUserId));
        redisTemplate.delete(validationKey);
    }

    /**
     * Generate random OTP
     */
    private String generateRandomOtp() {
        Random random = new Random();
        StringBuilder otp = new StringBuilder();
        for (int i = 0; i < otpLength; i++) {
            otp.append(random.nextInt(10));
        }
        return otp.toString();
    }
}

