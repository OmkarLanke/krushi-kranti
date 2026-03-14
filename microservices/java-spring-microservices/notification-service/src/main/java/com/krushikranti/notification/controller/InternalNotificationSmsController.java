package com.krushikranti.notification.controller;

import com.krushikranti.notification.service.SmsService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Internal endpoint for other services to trigger SMS notifications.
 * Used by auth-service to send OTPs via SMS.
 */
@RestController
@RequestMapping("/notification")
@RequiredArgsConstructor
@Slf4j
public class InternalNotificationSmsController {

    private final SmsService smsService;

    @PostMapping("/send-sms")
    public ResponseEntity<Map<String, Object>> sendSms(@RequestBody SendSmsRequest request) {
        log.info("Received SMS send request for phone: {}", request.getPhoneNumber());

        if (request.getPhoneNumber() == null || request.getPhoneNumber().isBlank()) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Phone number is required");
            return ResponseEntity.badRequest().body(response);
        }

        try {
            smsService.sendOtpSms(request.getPhoneNumber(), request.getName(), request.getOtp());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "SMS sent successfully");
            return ResponseEntity.ok(response);
        } catch (Exception ex) {
            log.error("Failed to send SMS to: {}", request.getPhoneNumber(), ex);

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to send SMS: " + ex.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @Data
    public static class SendSmsRequest {
        private String phoneNumber;
        private String name;
        private String otp;
    }
}
