package com.krushikranti.jobapplication.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Client service for sending emails via notification-service
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationClientService {

    private final WebClient.Builder webClientBuilder;

    @Value("${notification.service.url:http://notification-service:4016}")
    private String notificationServiceUrl;

    /**
     * Send HR interview invitation email
     */
    public Mono<Void> sendHRInvitationEmail(
            String recipientEmail,
            String applicantName,
            LocalDate interviewDate,
            LocalTime interviewTime,
            String venue,
            List<String> requiredDocuments) {

        log.info("Sending HR invitation email to: {}", recipientEmail);

        Map<String, Object> emailRequest = new HashMap<>();
        emailRequest.put("to", recipientEmail);
        emailRequest.put("subject", "HR Interview Scheduled - KrushiKranti");
        
        // Build email body
        String emailBody = buildHRInvitationEmailBody(
                applicantName,
                interviewDate,
                interviewTime,
                venue,
                requiredDocuments
        );
        emailRequest.put("body", emailBody);
        emailRequest.put("isHtml", true);

        WebClient client = webClientBuilder.baseUrl(notificationServiceUrl).build();

        return client.post()
                .uri("/notification/send-email")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(emailRequest)
                .retrieve()
                .bodyToMono(Map.class)
                .doOnSuccess(response -> log.info("HR invitation email sent successfully to: {}", recipientEmail))
                .doOnError(error -> log.error("Failed to send HR invitation email to: {}", recipientEmail, error))
                .then();
    }

    /**
     * Send offer letter email with attachment
     */
    public Mono<Void> sendOfferLetterEmail(
            String recipientEmail,
            String applicantName,
            String roleName,
            String offerLetterUrl) {

        log.info("Sending offer letter email to: {}", recipientEmail);

        Map<String, Object> emailRequest = new HashMap<>();
        emailRequest.put("to", recipientEmail);
        emailRequest.put("subject", "Congratulations! Job Offer - KrushiKranti");
        
        // Build email body
        String emailBody = buildOfferLetterEmailBody(applicantName, roleName, offerLetterUrl);
        emailRequest.put("body", emailBody);
        emailRequest.put("isHtml", true);

        WebClient client = webClientBuilder.baseUrl(notificationServiceUrl).build();

        return client.post()
                .uri("/notification/send-email")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(emailRequest)
                .retrieve()
                .bodyToMono(Map.class)
                .doOnSuccess(response -> log.info("Offer letter email sent successfully to: {}", recipientEmail))
                .doOnError(error -> log.error("Failed to send offer letter email to: {}", recipientEmail, error))
                .then();
    }

    private String buildHRInvitationEmailBody(
            String applicantName,
            LocalDate interviewDate,
            LocalTime interviewTime,
            String venue,
            List<String> requiredDocuments) {

        String formattedDate = interviewDate.format(DateTimeFormatter.ofPattern("dd MMM yyyy"));
        String formattedTime = interviewTime.format(DateTimeFormatter.ofPattern("hh:mm a"));

        StringBuilder documentsHtml = new StringBuilder();
        for (String doc : requiredDocuments) {
            documentsHtml.append("<li style=\"margin: 8px 0;\">").append(doc).append("</li>");
        }

        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><meta charset=\"UTF-8\"></head>" +
                "<body style=\"font-family: Arial, sans-serif; line-height: 1.6; color: #333;\">" +
                "<div style=\"max-width: 600px; margin: 0 auto; padding: 20px;\">" +
                "<div style=\"background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;\">" +
                "<h1 style=\"margin: 0;\">HR Interview Scheduled</h1>" +
                "</div>" +
                "<div style=\"background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;\">" +
                "<p>Dear " + applicantName + ",</p>" +
                "<p>Congratulations! Your application has been shortlisted for an HR interview with KrushiKranti.</p>" +
                "<div style=\"background: white; padding: 20px; border-radius: 8px; margin: 20px 0;\">" +
                "<h2 style=\"color: #4CAF50; margin-top: 0;\">Interview Details</h2>" +
                "<p><strong>📅 Date:</strong> " + formattedDate + "</p>" +
                "<p><strong>🕐 Time:</strong> " + formattedTime + "</p>" +
                "<p><strong>📍 Venue:</strong> " + venue + "</p>" +
                "</div>" +
                "<div style=\"background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;\">" +
                "<h3 style=\"color: #856404; margin-top: 0;\">📋 Required Documents</h3>" +
                "<p style=\"color: #856404;\">Please bring the following documents:</p>" +
                "<ul style=\"color: #856404;\">" + documentsHtml.toString() + "</ul>" +
                "</div>" +
                "<p>We look forward to meeting you. If you have any questions, please don't hesitate to contact us.</p>" +
                "<p style=\"margin-top: 30px;\">Best regards,<br><strong>KrushiKranti HR Team</strong></p>" +
                "</div>" +
                "</div>" +
                "</body>" +
                "</html>";
    }

    private String buildOfferLetterEmailBody(String applicantName, String roleName, String offerLetterUrl) {
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><meta charset=\"UTF-8\"></head>" +
                "<body style=\"font-family: Arial, sans-serif; line-height: 1.6; color: #333;\">" +
                "<div style=\"max-width: 600px; margin: 0 auto; padding: 20px;\">" +
                "<div style=\"background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;\">" +
                "<h1 style=\"margin: 0;\">🎉 Congratulations!</h1>" +
                "</div>" +
                "<div style=\"background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;\">" +
                "<p>Dear " + applicantName + ",</p>" +
                "<p>We are pleased to offer you the position of <strong>" + roleName + "</strong> at KrushiKranti.</p>" +
                "<p>After careful consideration of your application and interview performance, we believe you will be a valuable addition to our team.</p>" +
                "<div style=\"text-align: center; margin: 30px 0;\">" +
                "<a href=\"" + offerLetterUrl + "\" style=\"display: inline-block; padding: 15px 40px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; font-weight: bold;\">📄 Download Offer Letter</a>" +
                "</div>" +
                "<p>Please review the attached offer letter carefully. We look forward to welcoming you to the KrushiKranti family!</p>" +
                "<p style=\"margin-top: 30px;\">Warm regards,<br><strong>KrushiKranti HR Team</strong></p>" +
                "</div>" +
                "</div>" +
                "</body>" +
                "</html>";
    }
}
