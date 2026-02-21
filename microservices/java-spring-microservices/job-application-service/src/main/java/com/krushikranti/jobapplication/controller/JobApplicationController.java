package com.krushikranti.jobapplication.controller;

import com.krushikranti.jobapplication.dto.ApplicationResponse;
import com.krushikranti.jobapplication.dto.CreateApplicationRequest;
import com.krushikranti.jobapplication.dto.ScheduleHRInterviewRequest;
import com.krushikranti.jobapplication.dto.UpdateStatusRequest;
import com.krushikranti.jobapplication.service.JobApplicationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/applications")
@RequiredArgsConstructor
public class JobApplicationController {

    private final JobApplicationService service;

    @PostMapping(consumes = { "multipart/form-data" })
    public Mono<ResponseEntity<ApplicationResponse>> create(
            @RequestParam("roleType") String roleType,
            @RequestParam("fullName") String fullName,
            @RequestParam(value = "mobile", required = false) String mobile,
            @RequestParam(value = "email", required = false) String email,
            @RequestParam(value = "dob", required = false) String dob,
            @RequestParam(value = "locationText", required = false) String locationText,
            @RequestParam(value = "highestQualification", required = false) String highestQualification,
            @RequestParam(value = "institution", required = false) String institution,
            @RequestParam(value = "yearOfCompletion", required = false) Integer yearOfCompletion,
            @RequestParam(value = "yearsExperience", required = false) Integer yearsExperience,
            @RequestParam(value = "relevantExperience", required = false) String relevantExperience,
            @RequestParam(value = "lastEmployerRole", required = false) String lastEmployerRole,
            @RequestParam(value = "vehicleAvailable", required = false) Boolean vehicleAvailable,
            @RequestParam(value = "willingForFieldVisit", required = false) Boolean willingForFieldVisit,
            @RequestPart(value = "resume", required = false) MultipartFile resume) {
        CreateApplicationRequest req = new CreateApplicationRequest();
        req.roleType = roleType;
        req.fullName = fullName;
        req.mobile = mobile;
        req.email = email;
        req.dob = dob;
        req.locationText = locationText;
        req.highestQualification = highestQualification;
        req.institution = institution;
        req.yearOfCompletion = yearOfCompletion;
        req.yearsExperience = yearsExperience;
        req.relevantExperience = relevantExperience;
        req.lastEmployerRole = lastEmployerRole;
        req.vehicleAvailable = vehicleAvailable;
        req.willingForFieldVisit = willingForFieldVisit;
        req.resume = resume;

        return service.createApplication(req)
                .map(resp -> ResponseEntity.created(URI.create("/api/applications/" + resp.applicantId)).body(resp));
    }

    @GetMapping
    public ResponseEntity<List<ApplicationResponse>> getAll(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "roleType", required = false) String roleType) {
        List<ApplicationResponse> applications = service.getAllApplications(status, roleType);
        return ResponseEntity.ok(applications);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApplicationResponse> getById(@PathVariable("id") UUID applicantId) {
        ApplicationResponse application = service.getApplicationById(applicantId);
        return ResponseEntity.ok(application);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApplicationResponse> updateStatus(
            @PathVariable("id") UUID applicantId,
            @RequestBody UpdateStatusRequest request) {
        ApplicationResponse updated = service.updateStatus(applicantId, request);
        return ResponseEntity.ok(updated);
    }

    /**
     * Schedule HR interview for an application
     * POST /api/applications/{id}/schedule-hr
     */
    @PostMapping("/{id}/schedule-hr")
    public ResponseEntity<ApplicationResponse> scheduleHRInterview(
            @PathVariable("id") UUID applicantId,
            @RequestBody ScheduleHRInterviewRequest request) {
        ApplicationResponse response = service.scheduleHRInterview(applicantId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Send offer letter to selected candidate
     * POST /api/applications/{id}/send-offer
     */
    @PostMapping(value = "/{id}/send-offer", consumes = { "multipart/form-data" })
    public Mono<ResponseEntity<ApplicationResponse>> sendOfferLetter(
            @PathVariable("id") UUID applicantId,
            @RequestPart("offerLetter") MultipartFile offerLetterPdf) {
        return service.sendOfferLetter(applicantId, offerLetterPdf)
                .map(ResponseEntity::ok);
    }

    /**
     * Reject an application
     * PUT /api/applications/{id}/reject
     */
    @PutMapping("/{id}/reject")
    public ResponseEntity<ApplicationResponse> rejectApplication(
            @PathVariable("id") UUID applicantId) {
        ApplicationResponse response = service.rejectApplication(applicantId);
        return ResponseEntity.ok(response);
    }
}
