package com.krushikranti.auth.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class OtpService {

    private final RedisTemplate<String, String> redisTemplate;

    @Value("${otp.expiration}")
    private int otpExpiration;

    @Value("${otp.length}")
    private int otpLength;

    public OtpService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public String generateOtp(String phoneNumber) {
        String otp = generateRandomOtp();
        String key = "otp:" + phoneNumber;
        
        redisTemplate.opsForValue().set(key, otp, otpExpiration, TimeUnit.SECONDS);
        log.debug("Generated OTP for phone: {}", phoneNumber);
        
        return otp;
    }

    public boolean validateOtp(String phoneNumber, String otp) {
        String key = "otp:" + phoneNumber;
        String storedOtp = redisTemplate.opsForValue().get(key);
        
        if (storedOtp != null && storedOtp.equals(otp)) {
            redisTemplate.delete(key);
            log.debug("OTP validated successfully for phone: {}", phoneNumber);
            return true;
        }
        
        log.debug("OTP validation failed for phone: {}", phoneNumber);
        return false;
    }

    /**
     * Get OTP for a phone number (for testing purposes only)
     * Does not delete the OTP
     */
    public String getOtp(String phoneNumber) {
        String key = "otp:" + phoneNumber;
        return redisTemplate.opsForValue().get(key);
    }

    public void deleteOtp(String phoneNumber) {
        String key = "otp:" + phoneNumber;
        redisTemplate.delete(key);
    }

    private String generateRandomOtp() {
        Random random = new Random();
        StringBuilder otp = new StringBuilder();
        for (int i = 0; i < otpLength; i++) {
            otp.append(random.nextInt(10));
        }
        return otp.toString();
    }
}

