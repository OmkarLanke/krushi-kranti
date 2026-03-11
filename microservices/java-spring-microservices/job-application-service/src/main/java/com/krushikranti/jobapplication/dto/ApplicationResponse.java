package com.krushikranti.jobapplication.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ApplicationResponse {
    public UUID applicantId;
    public String roleType;
    public String fullName;
    public String mobile;
    public String email;
    public OffsetDateTime dob;
    public String locationText;
    public String highestQualification;
    public String institution;
    public Integer yearOfCompletion;
    public Integer yearsExperience;
    public String relevantExperience;
    public String lastEmployerRole;
    public Boolean vehicleAvailable;
    public Boolean willingForFieldVisit;
    public String resumeUrl;
    public String currentStatus;
    public OffsetDateTime submittedAt;
    public OffsetDateTime updatedAt;
    
    // HR Interview fields
    public LocalDate hrInterviewDate;
    public LocalTime hrInterviewTime;
    public String hrInterviewVenue;
    public String hrRequiredDocuments;
    
    // Offer Letter fields
    public String offerLetterUrl;
    public OffsetDateTime offerSentAt;
}
