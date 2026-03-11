package com.krushikranti.support.dto;

import com.krushikranti.support.model.TicketMessageSenderType;
import com.krushikranti.support.model.TicketStatus;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class TicketSummaryDto {
    private Long id;
    private String title;
    private String category;
    private TicketStatus status;
    private String priority;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime lastMessageAt;
    private TicketMessageSenderType lastMessageBy;
    private boolean unreadForFarmer;
    private boolean unreadForAdmin;
}

