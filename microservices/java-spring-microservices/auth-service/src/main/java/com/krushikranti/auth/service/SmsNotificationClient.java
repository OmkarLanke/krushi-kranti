package com.krushikranti.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.Map;

/**
 * Client for sending SMS via notification-service.
 * Calls POST /notification/send-sms on the notification-service.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SmsNotificationClient {

    private final WebClient.Builder webClientBuilder;

    @Value("${app.services.notification-service:http://localhost:4016}")
    private String notificationServiceUrl;

    /**
     * Send OTP SMS via notification-service.
     *
     * @param phoneNumber Recipient phone number
     * @param name        Recipient name (for the DLT template)
     * @param otp         The OTP code
     */
    public void sendOtpSms(String phoneNumber, String name, String otp) {
        try {
            WebClient webClient = webClientBuilder.baseUrl(notificationServiceUrl).build();

            Map<String, String> requestBody = Map.of(
                    "phoneNumber", phoneNumber,
                    "name", name != null ? name : "User",
                    "otp", otp
            );

            webClient.post()
                    .uri("/notification/send-sms")
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .timeout(Duration.ofSeconds(15))
                    .doOnSuccess(response -> log.info("OTP SMS sent successfully to: {}", phoneNumber))
                    .doOnError(error -> log.error("Failed to send OTP SMS to: {}", phoneNumber, error))
                    .block();

        } catch (Exception e) {
            log.error("Error calling notification-service to send OTP SMS to {}: {}", phoneNumber, e.getMessage(), e);
            // Don't throw — SMS failure should not block the OTP flow.
            // The OTP is still stored in Redis and can be retrieved via the test endpoint during development.
        }
    }
}
