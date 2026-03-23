package com.krushikranti.jobapplication.controller;

import com.krushikranti.jobapplication.service.NotificationClientService;
import com.krushikranti.jobapplication.service.OtpService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
@Slf4j
public class EmailOtpController {

    private final OtpService otpService;
    private final NotificationClientService notificationClientService;

    @PostMapping("/send")
    public Mono<ResponseEntity<Map<String, Object>>> sendOtp(@RequestParam("email") String email) {
        String otp = otpService.generateOtp(email);

        Map<String, Object> emailRequest = new HashMap<>();
        emailRequest.put("to", email);
        emailRequest.put("subject", "Your OTP - Krushi Kranti");
        emailRequest.put("body", buildOtpEmailTemplate(otp));
        emailRequest.put("isHtml", true);

        return notificationClientService.sendGenericEmail(emailRequest)
                .then(Mono.fromSupplier(() -> {
                    Map<String, Object> resp = new HashMap<>();
                    resp.put("sent", true);
                    return ResponseEntity.ok(resp);
                }))
                .doOnError(err -> log.error("Failed to send OTP email", err));
    }

    @PostMapping("/verify")
    public ResponseEntity<Map<String, Object>> verifyOtp(@RequestBody VerifyRequest req) {
        boolean ok = otpService.validateOtp(req.getEmail(), req.getOtp());
        Map<String, Object> resp = new HashMap<>();
        resp.put("verified", ok);
        return ResponseEntity.ok(resp);
    }

    @Data
    public static class VerifyRequest {
        private String email;
        private String otp;
    }

    private String buildOtpEmailTemplate(String otp) {
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head>" +
                "<meta charset=\"UTF-8\">" +
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">" +
                "</head>" +
                "<body style=\"font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;\">" +
                "<div style=\"max-width: 500px; margin: 20px auto; background: white; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">" +

                "<!-- Header -->" +
                "<div style=\"background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px 20px; text-align: center; border-radius: 10px 10px 0 0;\">" +
                "<h1 style=\"margin: 0; font-size: 24px; font-weight: bold;\">Krushi Kranti</h1>" +
                "<p style=\"margin: 8px 0 0 0; font-size: 14px; opacity: 0.9;\">Job Application Verification</p>" +
                "</div>" +

                "<!-- Content -->" +
                "<div style=\"padding: 40px 30px; text-align: center;\">" +
                "<p style=\"margin: 0 0 20px 0; color: #333; font-size: 16px;\">" +
                "Dear Candidate, your Email Verification OTP is:" +
                "</p>" +

                "<!-- OTP Box -->" +
                "<div style=\"background: #f0f7f0; border: 2px solid #4CAF50; border-radius: 8px; padding: 25px; margin: 20px 0;\">" +
                "<p style=\"margin: 0; font-size: 12px; color: #666; text-transform: uppercase; letter-spacing: 2px;\">Verification Code</p>" +
                "<p style=\"margin: 12px 0 0 0; font-size: 42px; font-weight: bold; color: #4CAF50; letter-spacing: 8px;\">" + otp + "</p>" +
                "</div>" +

                "<p style=\"margin: 20px 0; color: #666; font-size: 14px;\">" +
                "This code is valid for <strong>5 minutes</strong>" +
                "</p>" +

                "<p style=\"margin: 10px 0 0 0; color: #666; font-size: 13px;\">" +
                "Visit: <a href=\"https://krushikranti.ltd\" style=\"color:#4CAF50; text-decoration:none;\">www.krushikranti.ltd</a>" +
                "</p>" +

                "<div style=\"background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 20px 0; border-radius: 4px; text-align: left;\">" +
                "<p style=\"margin: 0; color: #856404; font-size: 13px;\">" +
                "<strong>Security Tip:</strong> Never share this code with anyone. Krushi Kranti support will never ask for it." +
                "</p>" +
                "</div>" +
                "</div>" +

                "<!-- Footer -->" +
                "<div style=\"background: #f9f9f9; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; border-top: 1px solid #eee;\">" +
                "<p style=\"margin: 0; color: #999; font-size: 12px;\">" +
                "If you didn't request this code, please ignore this email." +
                "</p>" +
                "<p style=\"margin: 10px 0 0 0; color: #ccc; font-size: 11px;\">" +
                "© 2026 Krushi Kranti. All rights reserved." +
                "</p>" +
                "</div>" +
                "</div>" +
                "</body>" +
                "</html>";
    }
}

