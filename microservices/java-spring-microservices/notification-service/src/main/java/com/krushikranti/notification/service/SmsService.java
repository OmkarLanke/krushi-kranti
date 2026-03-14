package com.krushikranti.notification.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Service for sending SMS via Best SMS gateway.
 * Uses HTTP GET API: http://control.bestsms.co.in/api/sendhttp.php
 */
@Service
@Slf4j
public class SmsService {

    @Value("${app.sms.api-url}")
    private String apiUrl;

    @Value("${app.sms.auth-key}")
    private String authKey;

    @Value("${app.sms.sender-id}")
    private String senderId;

    @Value("${app.sms.route}")
    private String route;

    @Value("${app.sms.country}")
    private String country;

    @Value("${app.sms.dlt-te-id}")
    private String dltTeId;

    @Value("${app.sms.enabled:true}")
    private boolean smsEnabled;

    private final RestTemplate restTemplate;

    public SmsService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Send OTP SMS to a phone number using the DLT-registered template.
     * Template: "Dear {name}, Your Mobile Verification OTP is {otp}. Visit Now www.thynktech.ltd For more details THYNK TECH INDIA"
     *
     * @param phoneNumber Recipient phone number (with or without country code)
     * @param name        Recipient name (used in DLT template)
     * @param otp         The OTP code
     */
    public void sendOtpSms(String phoneNumber, String name, String otp) {
        if (!smsEnabled) {
            log.info("SMS is disabled. OTP for {}: {}", phoneNumber, otp);
            return;
        }

        String normalizedPhone = normalizePhoneNumber(phoneNumber);
        String recipientName = (name != null && !name.isBlank()) ? name : "User";

        // Build the message exactly matching the DLT template
        String message = "Dear " + recipientName + ", Your Mobile Verification OTP is " + otp
                + ". Visit Now www.thynktech.ltd For more details THYNK TECH INDIA";

        sendSms(normalizedPhone, message);
    }

    /**
     * Send a raw SMS message. The message must match a registered DLT template.
     *
     * @param phoneNumber Recipient phone number (with or without country code)
     * @param message     Message content (must match a DLT-registered template)
     */
    public void sendSms(String phoneNumber, String message) {
        if (!smsEnabled) {
            log.info("SMS is disabled. Message to {}: {}", phoneNumber, message);
            return;
        }

        String normalizedPhone = normalizePhoneNumber(phoneNumber);

        String url = UriComponentsBuilder.fromHttpUrl(apiUrl)
                .queryParam("authkey", authKey)
                .queryParam("mobiles", normalizedPhone)
                .queryParam("message", message)
                .queryParam("sender", senderId)
                .queryParam("route", route)
                .queryParam("country", country)
                .queryParam("DLT_TE_ID", dltTeId)
                .build()
                .toUriString();

        try {
            String response = restTemplate.getForObject(url, String.class);
            log.info("SMS sent to {}. Gateway response: {}", normalizedPhone, response);
        } catch (Exception e) {
            log.error("Failed to send SMS to {}: {}", normalizedPhone, e.getMessage(), e);
            throw new RuntimeException("Failed to send SMS: " + e.getMessage(), e);
        }
    }

    /**
     * Normalize phone number to include country code 91 prefix.
     * Handles formats: "9876543210", "09876543210", "+919876543210", "919876543210"
     */
    private String normalizePhoneNumber(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new IllegalArgumentException("Phone number cannot be empty");
        }

        String cleaned = phoneNumber.replaceAll("[^0-9]", "");

        if (cleaned.length() == 10) {
            return "91" + cleaned;
        } else if (cleaned.length() == 11 && cleaned.startsWith("0")) {
            return "91" + cleaned.substring(1);
        } else if (cleaned.length() == 12 && cleaned.startsWith("91")) {
            return cleaned;
        } else if (cleaned.length() == 13 && cleaned.startsWith("091")) {
            return cleaned.substring(1);
        }

        // Return as-is if no pattern matches
        return cleaned;
    }
}
