package com.krushikranti.support.dto;

import com.krushikranti.support.model.TicketStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateTicketStatusRequest {

    @NotNull
    private TicketStatus status;
}

