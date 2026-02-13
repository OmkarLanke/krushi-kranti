package com.krushikranti.jobapplication.dto;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Data
public class ScheduleHRInterviewRequest {
    private LocalDate interviewDate;
    private LocalTime interviewTime;
    private String venue;
    private List<String> requiredDocuments;
}
