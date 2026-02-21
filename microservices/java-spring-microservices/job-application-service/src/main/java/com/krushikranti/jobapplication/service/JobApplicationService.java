package com.krushikranti.jobapplication.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.krushikranti.jobapplication.domain.JobApplication;
import com.krushikranti.jobapplication.dto.ApplicationResponse;
import com.krushikranti.jobapplication.dto.CreateApplicationRequest;
import com.krushikranti.jobapplication.dto.ScheduleHRInterviewRequest;
import com.krushikranti.jobapplication.dto.UpdateStatusRequest;
import com.krushikranti.jobapplication.repository.JobApplicationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class JobApplicationService {

    private final JobApplicationRepository repository;
    private final FileForwardingService fileForwardingService;
    private final NotificationClientService notificationClientService;
    private final ObjectMapper objectMapper;

    public Mono<ApplicationResponse> createApplication(CreateApplicationRequest req) {
        MultipartFile resume = req.resume;

        Mono<Map> uploadMono = Mono.empty();
        if (resume != null && !resume.isEmpty()) {
            uploadMono = fileForwardingService.forward(resume, "job-applications", null);
        }

        return uploadMono
                .defaultIfEmpty(Map.of())
                .map(map -> {
                    String resumeUrl = null;
                    try {
                        Map data = (Map) map.get("data");
                        if (data != null && data.get("url") != null)
                            resumeUrl = data.get("url").toString();
                    } catch (Exception ignored) {
                    }

                    JobApplication entity = new JobApplication();
                    entity.setApplicantId(UUID.randomUUID());
                    entity.setRoleType(req.roleType);
                    entity.setFullName(req.fullName);
                    entity.setMobile(req.mobile);
                    entity.setEmail(req.email);
                    
                    // Parse DOB from ISO 8601 string to OffsetDateTime
                    log.info("Received DOB parameter: '{}'", req.dob);
                    if (req.dob != null && !req.dob.isEmpty()) {
                        try {
                            OffsetDateTime parsedDob;
                            if (req.dob.contains("T") && !req.dob.contains("Z") && !req.dob.contains("+")) {
                                // Handle ISO string without timezone (e.g., "2006-02-21T00:00:00.000")
                                LocalDateTime localDateTime = LocalDateTime.parse(req.dob);
                                parsedDob = localDateTime.atOffset(ZoneOffset.UTC);
                            } else {
                                // Handle full ISO string with timezone
                                parsedDob = OffsetDateTime.parse(req.dob);
                            }
                            entity.setDob(parsedDob);
                            log.info("Successfully parsed DOB: {}", parsedDob);
                        } catch (Exception e) {
                            log.warn("Failed to parse DOB: {} - Error: {}", req.dob, e.getMessage());
                        }
                    } else {
                        log.warn("DOB parameter is null or empty");
                    }
                    
                    entity.setLocationText(req.locationText);
                    entity.setHighestQualification(req.highestQualification);
                    entity.setInstitution(req.institution);
                    entity.setYearOfCompletion(req.yearOfCompletion);
                    entity.setYearsExperience(req.yearsExperience);
                    entity.setRelevantExperience(req.relevantExperience);
                    entity.setLastEmployerRole(req.lastEmployerRole);
                    entity.setVehicleAvailable(req.vehicleAvailable);
                    entity.setWillingForFieldVisit(req.willingForFieldVisit);
                    entity.setResumeUrl(resumeUrl);
                    entity.setCurrentStatus("SCREENING");
                    entity.setSubmittedAt(OffsetDateTime.now());
                    entity.setUpdatedAt(OffsetDateTime.now());

                    repository.save(entity);

                    ApplicationResponse resp = new ApplicationResponse();
                    resp.applicantId = entity.getApplicantId();
                    resp.fullName = entity.getFullName();
                    resp.roleType = entity.getRoleType();
                    resp.resumeUrl = entity.getResumeUrl();
                    resp.currentStatus = entity.getCurrentStatus();
                    resp.submittedAt = entity.getSubmittedAt();
                    return resp;
                });
    }

    public List<ApplicationResponse> getAllApplications(String status, String roleType) {
        List<JobApplication> applications;
        
        if (status != null || roleType != null) {
            applications = repository.findWithFilters(status, roleType);
        } else {
            applications = repository.findAll();
        }
        
        return applications.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public ApplicationResponse getApplicationById(UUID applicantId) {
        JobApplication application = repository.findById(applicantId)
                .orElseThrow(() -> new RuntimeException("Application not found with id: " + applicantId));
        return toResponse(application);
    }

    public ApplicationResponse updateStatus(UUID applicantId, UpdateStatusRequest request) {
        JobApplication application = repository.findById(applicantId)
                .orElseThrow(() -> new RuntimeException("Application not found with id: " + applicantId));
        
        application.setCurrentStatus(request.status);
        application.setUpdatedAt(OffsetDateTime.now());
        
        repository.save(application);
        
        // TODO: Publish Kafka event for status change
        // kafkaTemplate.send("JOB_APPLICATION_STATUS_CHANGED", event);
        
        return toResponse(application);
    }
/**
     * Schedule HR interview and update status to SELECTED_FOR_HR
     */
    public ApplicationResponse scheduleHRInterview(UUID applicantId, ScheduleHRInterviewRequest request) {
        JobApplication application = repository.findById(applicantId)
                .orElseThrow(() -> new RuntimeException("Application not found with id: " + applicantId));

        // Validate current status
        if (!"SCREENING".equals(application.getCurrentStatus())) {
            throw new RuntimeException("Can only schedule HR interview for applications in SCREENING status");
        }

        // Update HR interview details
        application.setHrInterviewDate(request.getInterviewDate());
        application.setHrInterviewTime(request.getInterviewTime());
        application.setHrInterviewVenue(request.getVenue());
        
        // Convert required documents list to JSON string
        try {
            String documentsJson = objectMapper.writeValueAsString(request.getRequiredDocuments());
            application.setHrRequiredDocuments(documentsJson);
        } catch (Exception e) {
            throw new RuntimeException("Error serializing required documents", e);
        }

        // Update status
        application.setCurrentStatus("SELECTED_FOR_HR");
        application.setUpdatedAt(OffsetDateTime.now());

        repository.save(application);

        // Send HR invitation email via notification service
        notificationClientService.sendHRInvitationEmail(
                application.getEmail(),
                application.getFullName(),
                request.getInterviewDate(),
                request.getInterviewTime(),
                request.getVenue(),
                request.getRequiredDocuments()
        ).subscribe(
                success -> log.info("HR invitation email sent successfully for applicant: {}", applicantId),
                error -> log.error("Failed to send HR invitation email for applicant: {}", applicantId, error)
        );

        return toResponse(application);
    }

    /**
     * Send offer letter and update status to SELECTED (hired)
     */
    public Mono<ApplicationResponse> sendOfferLetter(UUID applicantId, MultipartFile offerLetterPdf) {
        JobApplication application = repository.findById(applicantId)
                .orElseThrow(() -> new RuntimeException("Application not found with id: " + applicantId));

        // Validate current status
        if (!"SELECTED_FOR_HR".equals(application.getCurrentStatus())) {
            throw new RuntimeException("Can only send offer letter to applications with SELECTED_FOR_HR status");
        }

        // Upload offer letter PDF to file service
        return fileForwardingService.forward(offerLetterPdf, "offer-letters", null)
                .map(uploadResponse -> {
                    String offerLetterUrl = null;
                    try {
                        Map data = (Map) uploadResponse.get("data");
                        if (data != null && data.get("url") != null) {
                            offerLetterUrl = data.get("url").toString();
                        }
                    } catch (Exception ignored) {
                    }

                    if (offerLetterUrl == null) {
                        throw new RuntimeException("Failed to upload offer letter");
                    }

                    // Update application
                    application.setOfferLetterUrl(offerLetterUrl);
                    application.setOfferSentAt(OffsetDateTime.now());
                    application.setCurrentStatus("SELECTED");
                    application.setUpdatedAt(OffsetDateTime.now());

                    repository.save(application);

                    // Send offer letter email via notification service
                    notificationClientService.sendOfferLetterEmail(
                            application.getEmail(),
                            application.getFullName(),
                            application.getRoleType(),
                            offerLetterUrl
                    ).subscribe(
                            success -> log.info("Offer letter email sent successfully for applicant: {}", applicantId),
                            error -> log.error("Failed to send offer letter email for applicant: {}", applicantId, error)
                    );

                    return toResponse(application);
                });
    }

    /**
     * Reject application
     */
    public ApplicationResponse rejectApplication(UUID applicantId) {
        JobApplication application = repository.findById(applicantId)
                .orElseThrow(() -> new RuntimeException("Application not found with id: " + applicantId));

        // Can reject from any status except already SELECTED or REJECTED
        if ("SELECTED".equals(application.getCurrentStatus())) {
            throw new RuntimeException("Cannot reject an already selected candidate");
        }
        if ("REJECTED".equals(application.getCurrentStatus())) {
            throw new RuntimeException("Application is already rejected");
        }

        application.setCurrentStatus("REJECTED");
        application.setUpdatedAt(OffsetDateTime.now());

        repository.save(application);

        // Note: No rejection email as per requirement

        return toResponse(application);
    }

    
    private ApplicationResponse toResponse(JobApplication entity) {
        ApplicationResponse resp = new ApplicationResponse();
        resp.applicantId = entity.getApplicantId();
        resp.fullName = entity.getFullName();
        resp.roleType = entity.getRoleType();
        resp.mobile = entity.getMobile();
        resp.email = entity.getEmail();
        resp.dob = entity.getDob();
        resp.locationText = entity.getLocationText();
        resp.highestQualification = entity.getHighestQualification();
        resp.institution = entity.getInstitution();
        resp.yearOfCompletion = entity.getYearOfCompletion();
        resp.yearsExperience = entity.getYearsExperience();
        resp.relevantExperience = entity.getRelevantExperience();
        resp.lastEmployerRole = entity.getLastEmployerRole();
        resp.vehicleAvailable = entity.getVehicleAvailable();
        resp.willingForFieldVisit = entity.getWillingForFieldVisit();
        resp.resumeUrl = entity.getResumeUrl();
        resp.currentStatus = entity.getCurrentStatus();
        resp.submittedAt = entity.getSubmittedAt();
        resp.updatedAt = entity.getUpdatedAt();
        resp.hrInterviewDate = entity.getHrInterviewDate();
        resp.hrInterviewTime = entity.getHrInterviewTime();
        resp.hrInterviewVenue = entity.getHrInterviewVenue();
        resp.hrRequiredDocuments = entity.getHrRequiredDocuments();
        resp.offerLetterUrl = entity.getOfferLetterUrl();
        resp.offerSentAt = entity.getOfferSentAt();
        return resp;
    }
}
