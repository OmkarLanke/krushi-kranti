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
        // Rate limiting key: farm_verification_otp_rate_limit:{farmId}:{fieldOfficerUserId}
        String rateLimitKey = "farm_verification_otp_rate_limit:" + farmId + ":" + fieldOfficerUserId;
        
        // Use atomic increment to check and update rate limit in one operation
        Long currentCount = redisTemplate.opsForValue().increment(rateLimitKey);
        
        // If this is the first request (count == 1), set expiration
        if (currentCount == 1) {
            redisTemplate.expire(rateLimitKey, 1, TimeUnit.HOURS);
        }
        
        // Check if rate limit exceeded (after increment, so we check if count > max)
        if (currentCount > maxRequestsPerHour) {
            // Decrement since we're rejecting the request
            redisTemplate.opsForValue().decrement(rateLimitKey);
            log.warn("OTP rate limit exceeded - Farm ID: {}, Field Officer User ID: {}, Count: {}", 
                    farmId, fieldOfficerUserId, currentCount);
            throw new IllegalStateException(
                    "Maximum OTP requests exceeded. Please wait before requesting again.");
        }

        // Generate OTP
        String otp = generateRandomOtp();
        
        // Store OTP with key: farm_verification_otp:{farmId}:{farmerUserId}
        String otpKey = "farm_verification_otp:" + farmId + ":" + farmerUserId;
        
        // Store OTP with metadata (field officer ID for audit)
        String otpValue = otp + ":" + fieldOfficerUserId;
        redisTemplate.opsForValue().set(otpKey, otpValue, otpExpiration, TimeUnit.SECONDS);
        
        log.info("Generated OTP for farm verification - Farm ID: {}, Farmer User ID: {}, Field Officer User ID: {}, Rate Limit Count: {}", 
                farmId, farmerUserId, fieldOfficerUserId, currentCount);
        
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
        String otpKey = "farm_verification_otp:" + farmId + ":" + farmerUserId;
        
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
            String validationKey = "farm_verification_otp_validated:" + farmId + ":" + farmerUserId;
            redisTemplate.opsForValue().set(validationKey, "true", 1, TimeUnit.HOURS);
            
            log.info("OTP validated successfully - Farm ID: {}, Farmer User ID: {}, Validation Key: {}", 
                    farmId, farmerUserId, validationKey);
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
        String validationKey = "farm_verification_otp_validated:" + farmId + ":" + farmerUserId;
        
        String validated = redisTemplate.opsForValue().get(validationKey);
        boolean isValid = "true".equals(validated);
        
        log.info("Checking OTP validation - Farm ID: {}, Farmer User ID: {}, Validation Key: {}, Redis Value: {}, Is Valid: {}", 
                farmId, farmerUserId, validationKey, validated, isValid);
        
        // Also check if there are any similar keys (for debugging)
        if (!isValid) {
            try {
                java.util.Set<String> keys = redisTemplate.keys("farm_verification_otp_validated:" + farmId + ":*");
                log.warn("OTP validation key not found. Searched for: {}. Found similar keys: {}", validationKey, keys);
            } catch (Exception e) {
                log.warn("Could not search for similar keys: {}", e.getMessage());
            }
        }
        
        return isValid;
    }

    /**
     * Clear OTP validation status (useful for testing or reset)
     */
    public void clearOtpValidation(Long farmId, Long farmerUserId) {
        String validationKey = "farm_verification_otp_validated:" + farmId + ":" + farmerUserId;
        redisTemplate.delete(validationKey);
    }
    
    /**
     * Clear rate limit for a specific farm and field officer (useful for testing or reset)
     */
    public void clearRateLimit(Long farmId, Long fieldOfficerUserId) {
        String rateLimitKey = "farm_verification_otp_rate_limit:" + farmId + ":" + fieldOfficerUserId;
        redisTemplate.delete(rateLimitKey);
        log.info("Cleared rate limit for Farm ID: {}, Field Officer User ID: {}", farmId, fieldOfficerUserId);
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

