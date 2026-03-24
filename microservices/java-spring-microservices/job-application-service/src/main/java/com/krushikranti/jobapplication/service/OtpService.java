package com.krushikranti.jobapplication.service;

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

    @Value("${otp.expiration:300}")
    private int otpExpiration;

    @Value("${otp.length:6}")
    private int otpLength;

    public OtpService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public int getOtpExpirationMinutes() {
        // Convert seconds to minutes; minimum of 1 minute displayed
        return Math.max(1, otpExpiration / 60);
    }

    public String generateOtp(String email) {
        String otp = generateRandomOtp();
        String key = "otp:email:" + email;

        redisTemplate.opsForValue().set(key, otp, otpExpiration, TimeUnit.SECONDS);
        log.debug("Generated OTP for email: {}", email);

        return otp;
    }

    public boolean validateOtp(String email, String otp) {
        String key = "otp:email:" + email;
        String storedOtp = redisTemplate.opsForValue().get(key);

        if (storedOtp != null && storedOtp.equals(otp)) {
            redisTemplate.delete(key);
            // set verified flag for email for 24 hours
            redisTemplate.opsForValue().set("email_verified:" + email, "true", 24, TimeUnit.HOURS);
            log.debug("OTP validated successfully for email: {}", email);
            return true;
        }

        log.debug("OTP validation failed for email: {}", email);
        return false;
    }

    public boolean isEmailVerified(String email) {
        String key = "email_verified:" + email;
        String val = redisTemplate.opsForValue().get(key);
        return val != null && val.equals("true");
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

