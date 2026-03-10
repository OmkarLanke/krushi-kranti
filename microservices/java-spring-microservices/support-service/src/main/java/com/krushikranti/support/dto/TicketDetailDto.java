package com.krushikranti.support.dto;

import com.krushikranti.support.model.TicketStatus;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class TicketDetailDto {
    private Long id;
    private Long farmerId;
    private String title;
    private String category;
    private TicketStatus status;
    private String priority;
    private Long assignedAdminId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<TicketMessageDto> messages;
}

