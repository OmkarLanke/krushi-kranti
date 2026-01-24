package com.krushikranti.notification.controller;

import com.krushikranti.notification.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST API for sending emails (internal service-to-service communication)
 */
@RestController
@RequestMapping("/email")
@RequiredArgsConstructor
@Slf4j
public class EmailController {
    
    private final EmailService emailService;
    
    @Value("${app.email.reset-password.deep-link}")
    private String resetPasswordDeepLink;
    
    /**
     * Send password reset email
     * POST /email/password-reset
     * Internal endpoint - should be called by auth-service
     */
    @PostMapping("/password-reset")
    public ResponseEntity<Map<String, Object>> sendPasswordResetEmail(
            @RequestBody PasswordResetEmailRequest request) {
        
        log.info("Received password reset email request for: {}", request.getEmail());
        
        try {
            emailService.sendPasswordResetEmail(
                    request.getEmail(),
                    request.getUserName(),
                    request.getResetToken()
            );
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Password reset email sent successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", request.getEmail(), e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to send email: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Redirect endpoint for password reset - opens the app via deep link
     * GET /email/reset-password/redirect?token=xxx
     * This endpoint serves an HTML page that redirects to the app deep link
     */
    @GetMapping(value = "/reset-password/redirect", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> redirectToApp(@RequestParam("token") String token) {
        log.info("Password reset redirect requested for token");
        
        String deepLink = resetPasswordDeepLink + "?token=" + token;
        
        String html = "<!DOCTYPE html>" +
                "<html>" +
                "<head>" +
                "<meta charset=\"UTF-8\">" +
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">" +
                "<title>Opening Krushi Kranti...</title>" +
                "<style>" +
                "body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); }" +
                ".container { text-align: center; color: white; padding: 40px; }" +
                "h1 { font-size: 28px; margin-bottom: 20px; }" +
                "p { font-size: 16px; margin-bottom: 30px; }" +
                ".button { display: inline-block; padding: 15px 40px; background: white; color: #4CAF50; text-decoration: none; border-radius: 30px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }" +
                ".button:hover { transform: scale(1.05); }" +
                ".spinner { width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.3); border-top: 4px solid white; border-radius: 50%; animation: spin 1s linear infinite; margin: 20px auto; }" +
                "@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }" +
                "</style>" +
                "</head>" +
                "<body>" +
                "<div class=\"container\">" +
                "<h1>🌾 Krushi Kranti</h1>" +
                "<div class=\"spinner\"></div>" +
                "<p>Opening the app to reset your password...</p>" +
                "<p style=\"font-size: 14px; opacity: 0.8;\">If the app doesn't open automatically:</p>" +
                "<a href=\"" + deepLink + "\" class=\"button\">Open App</a>" +
                "</div>" +
                "<script>" +
                "setTimeout(function() { window.location.href = '" + deepLink + "'; }, 1000);" +
                "</script>" +
                "</body>" +
                "</html>";
        
        return ResponseEntity.ok(html);
    }
    
    /**
     * Request DTO for password reset email
     */
    public static class PasswordResetEmailRequest {
        private String email;
        private String userName;
        private String resetToken;
        
        public String getEmail() {
            return email;
        }
        
        public void setEmail(String email) {
            this.email = email;
        }
        
        public String getUserName() {
            return userName;
        }
        
        public void setUserName(String userName) {
            this.userName = userName;
        }
        
        public String getResetToken() {
            return resetToken;
        }
        
        public void setResetToken(String resetToken) {
            this.resetToken = resetToken;
        }
    }
}
