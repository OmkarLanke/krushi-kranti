package com.krushikranti.jobapplication.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "job_applications")
@Data
public class JobApplication {
    @Id
    @Column(name = "applicant_id")
    private UUID applicantId;

    @Column(name = "role_type", nullable = false)
    private String roleType;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "mobile")
    private String mobile;

    @Column(name = "email")
    private String email;

    @Column(name = "dob")
    private OffsetDateTime dob;

    @Column(name = "location_text")
    private String locationText;

    @Column(name = "highest_qualification")
    private String highestQualification;

    @Column(name = "institution")
    private String institution;

    @Column(name = "year_of_completion")
    private Integer yearOfCompletion;

    @Column(name = "years_experience")
    private Integer yearsExperience;

    @Column(name = "relevant_experience", columnDefinition = "text")
    private String relevantExperience;

    @Column(name = "last_employer_role")
    private String lastEmployerRole;

    @Column(name = "vehicle_available")
    private Boolean vehicleAvailable;

    @Column(name = "willing_for_field_visit")
    private Boolean willingForFieldVisit;

    @Column(name = "resume_url")
    private String resumeUrl;

    @Column(name = "current_status")
    private String currentStatus;

    @Column(name = "submitted_at")
    private OffsetDateTime submittedAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    // HR Interview fields
    @Column(name = "hr_interview_date")
    private LocalDate hrInterviewDate;

    @Column(name = "hr_interview_time")
    private LocalTime hrInterviewTime;

    @Column(name = "hr_interview_venue")
    private String hrInterviewVenue;

    @Column(name = "hr_required_documents", columnDefinition = "text")
    private String hrRequiredDocuments; // Stored as JSON string

    // Offer Letter fields
    @Column(name = "offer_letter_url")
    private String offerLetterUrl;

    @Column(name = "offer_sent_at")
    private OffsetDateTime offerSentAt;
}
