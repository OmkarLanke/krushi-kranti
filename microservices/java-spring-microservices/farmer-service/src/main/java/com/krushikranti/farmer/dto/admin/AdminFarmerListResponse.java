package com.krushikranti.farmer.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Response DTO for paginated farmer list
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminFarmerListResponse {
    
    private List<AdminFarmerSummaryDto> farmers;
    private int currentPage;
    private int totalPages;
    private long totalElements;
    private int pageSize;
    private boolean hasNext;
    private boolean hasPrevious;
    
    // Summary statistics
    private AdminDashboardStats stats;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdminDashboardStats {
        private long totalFarmers;
        private long pendingKyc;
        private long verifiedKyc;
        private long activeSubscriptions;
        private long pendingSubscriptions;
        private long totalFarms;
        private long verifiedFarms;
    }
}

