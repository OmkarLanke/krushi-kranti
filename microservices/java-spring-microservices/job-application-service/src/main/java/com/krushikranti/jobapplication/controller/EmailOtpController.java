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
        emailRequest.put("subject", "Your verification code");
        emailRequest.put("body", "Your verification code is: " + otp);
        emailRequest.put("isHtml", false);

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
}

