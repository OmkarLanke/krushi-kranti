package com.krushikranti.notification.controller;

import com.krushikranti.notification.service.EmailService;
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
 * Internal endpoint for other services to trigger email notifications.
 */
@RestController
@RequestMapping("/notification")
@RequiredArgsConstructor
@Slf4j
public class InternalNotificationEmailController {

    private final EmailService emailService;

    @PostMapping("/send-email")
    public ResponseEntity<Map<String, Object>> sendEmail(@RequestBody SendEmailRequest request) {
        log.info("Received email send request for: {}", request.getTo());

        if (request.getTo() == null || request.getTo().isBlank()) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Recipient email is required");
            return ResponseEntity.badRequest().body(response);
        }

        boolean isHtml = request.getIsHtml() != null ? request.getIsHtml() : true;

        try {
            emailService.sendEmail(request.getTo(), request.getSubject(), request.getBody(), isHtml);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Email sent successfully");
            return ResponseEntity.ok(response);
        } catch (Exception ex) {
            log.error("Failed to send email to: {}", request.getTo(), ex);

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to send email: " + ex.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @Data
    public static class SendEmailRequest {
        private String to;
        private String subject;
        private String body;
        private Boolean isHtml;
    }
}
