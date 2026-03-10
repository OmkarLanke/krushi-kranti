package com.krushikranti.support.dto;

import com.krushikranti.support.model.TicketMessageSenderType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class TicketMessageDto {
    private Long id;
    private TicketMessageSenderType senderType;
    private Long senderId;
    private String content;
    private LocalDateTime createdAt;
}

