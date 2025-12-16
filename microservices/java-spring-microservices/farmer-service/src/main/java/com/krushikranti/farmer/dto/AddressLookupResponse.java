package com.krushikranti.farmer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddressLookupResponse {
    private String pincode;
    private String district;
    private String taluka;
    private String state;
    private List<String> villages;
}

