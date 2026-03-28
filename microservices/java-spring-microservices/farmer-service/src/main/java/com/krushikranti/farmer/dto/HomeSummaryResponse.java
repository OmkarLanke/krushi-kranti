package com.krushikranti.farmer.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HomeSummaryResponse {
    private boolean hasPersonalDetails;
    private boolean hasCrops;
    private boolean allFarmsVerified;
    private long totalFarms;
    private long verifiedFarms;
}
