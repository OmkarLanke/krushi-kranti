package com.krushikranti.jobapplication.dto;

import org.springframework.web.multipart.MultipartFile;

public class CreateApplicationRequest {
    public String roleType;
    public String fullName;
    public String mobile;
    public String email;
    public String dob; // simple ISO date string
    public String locationText;
    public String highestQualification;
    public String institution;
    public Integer yearOfCompletion;
    public Integer yearsExperience;
    public String relevantExperience;
    public String lastEmployerRole;
    public Boolean vehicleAvailable;
    public Boolean willingForFieldVisit;
    public MultipartFile resume;
}

