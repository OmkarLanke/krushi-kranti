package com.krushikranti.farmer.dto;

import com.krushikranti.farmer.model.Farmer.Gender;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MyDetailsResponse {
    private Long id;
    private Long userId;
    private String firstName;
    private String lastName;
    private LocalDate dateOfBirth;
    private Gender gender;
    private String email; // From Auth Service
    private String phoneNumber; // From Auth Service
    private String alternatePhone;
    private String pincode;
    private String village;
    private String district;
    private String taluka;
    private String state;
}

