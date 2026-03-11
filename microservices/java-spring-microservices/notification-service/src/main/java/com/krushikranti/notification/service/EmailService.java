package com.krushikranti.notification.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

/**
 * Service for sending emails.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.email.from}")
    private String fromEmail;

    @Value("${app.email.from-name:Krushi Kranti}")
    private String fromName;

    @Value("${app.email.reset-password.base-url}")
    private String resetPasswordBaseUrl;

    @Value("${app.email.reset-password.deep-link}")
    private String resetPasswordDeepLink;
    
    @Value("${app.email.reset-password.redirect-url:}")
    private String resetPasswordRedirectUrl;

    /**
     * Send password reset email with reset link.
     *
     * @param toEmail Recipient email address
     * @param userName User's name (for personalization)
     * @param resetToken Password reset token
     */
    public void sendPasswordResetEmail(String toEmail, String userName, String resetToken) {
        log.info("Sending password reset email to: {}", toEmail);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject("Reset Your Password - Krushi Kranti");

            // Generate reset links
            String webLink = resetPasswordBaseUrl + "?token=" + resetToken;
            String deepLink = resetPasswordDeepLink + "?token=" + resetToken;
            
            // Use redirect URL if configured (for email clients that don't support custom schemes)
            // Otherwise fall back to deep link
            String buttonLink = (resetPasswordRedirectUrl != null && !resetPasswordRedirectUrl.isEmpty())
                    ? resetPasswordRedirectUrl + "?token=" + resetToken
                    : deepLink;

            // Create HTML email body
            String htmlBody = buildPasswordResetEmailHtml(userName, buttonLink, deepLink, resetToken);
            String textBody = buildPasswordResetEmailText(userName, webLink, deepLink, resetToken);

            helper.setText(textBody, htmlBody);

            mailSender.send(message);
            log.info("Password reset email sent successfully to: {}", toEmail);
        } catch (MessagingException e) {
            log.error("Failed to send password reset email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send password reset email: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error sending password reset email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send password reset email: " + e.getMessage(), e);
        }
    }

    /**
     * Send a generic email that can be triggered by other services.
     */
    public void sendEmail(String toEmail, String subject, String body, boolean isHtml) {
        log.info("Sending email to: {}", toEmail);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject(subject != null && !subject.isBlank() ? subject : "Notification from Krushi Kranti");
            helper.setText(body != null ? body : "", isHtml);

            mailSender.send(message);
            log.info("Email sent successfully to: {}", toEmail);
        } catch (MessagingException e) {
            log.error("Failed to send email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send email: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Unexpected error sending email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send email: " + e.getMessage(), e);
        }
    }

    /**
     * Build HTML email body for password reset.
     */
    private String buildPasswordResetEmailHtml(String userName, String buttonLink, String deepLink, String token) {
        String userDisplayName = userName != null ? userName : "User";
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head>" +
                "<meta charset=\"UTF-8\">" +
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">" +
                "<style>" +
                "body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }" +
                ".container { max-width: 600px; margin: 0 auto; padding: 20px; }" +
                ".header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }" +
                ".content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }" +
                ".button { display: inline-block; padding: 12px 30px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }" +
                ".button:hover { background-color: #45a049; }" +
                ".footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }" +
                ".token-box { background: #fff; padding: 15px; border: 2px dashed #4CAF50; border-radius: 5px; margin: 20px 0; text-align: center; font-family: monospace; word-break: break-all; }" +
                "</style>" +
                "</head>" +
                "<body>" +
                "<div class=\"container\">" +
                "<div class=\"header\">" +
                "<h1>Krushi Kranti</h1>" +
                "<p>Password Reset Request</p>" +
                "</div>" +
                "<div class=\"content\">" +
                "<p>Hello " + userDisplayName + ",</p>" +
                "<p>We received a request to reset your password. Click the button below to open the app and reset it:</p>" +
                "<p style=\"text-align: center;\">" +
                "<a href=\"" + buttonLink + "\" class=\"button\">Reset Password</a>" +
                "</p>" +
                "<p><strong>This link will expire in 30 minutes.</strong></p>" +
                "<p>If you didn't request a password reset, please ignore this email. Your password will remain unchanged.</p>" +
                "<p style=\"margin-top: 20px; font-size: 12px; color: #666;\">If the button doesn't work, copy and paste this link in your mobile browser:</p>" +
                "<div class=\"token-box\" style=\"font-size: 11px;\">" + deepLink + "</div>" +
                "</div>" +
                "<div class=\"footer\">" +
                "<p>This is an automated email. Please do not reply.</p>" +
                "<p>&copy; 2024 Krushi Kranti. All rights reserved.</p>" +
                "</div>" +
                "</div>" +
                "</body>" +
                "</html>";
    }

    /**
     * Build plain text email body for password reset.
     */
    private String buildPasswordResetEmailText(String userName, String webLink, String deepLink, String token) {
        String userDisplayName = userName != null ? userName : "User";
        return "Krushi Kranti - Password Reset Request\n\n" +
                "Hello " + userDisplayName + ",\n\n" +
                "We received a request to reset your password. Please click the link below to open the app and reset it:\n\n" +
                deepLink + "\n\n" +
                "This link will expire in 30 minutes.\n\n" +
                "If you didn't request a password reset, please ignore this email. Your password will remain unchanged.\n\n" +
                "---\n" +
                "This is an automated email. Please do not reply.\n" +
                "© 2024 Krushi Kranti. All rights reserved.";
    }
}
