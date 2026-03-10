package com.krushikranti.support.controller;

import com.krushikranti.support.dto.AddMessageRequest;
import com.krushikranti.support.dto.ApiResponse;
import com.krushikranti.support.dto.CreateTicketRequest;
import com.krushikranti.support.dto.TicketDetailDto;
import com.krushikranti.support.dto.TicketSummaryDto;
import com.krushikranti.support.service.SupportTicketService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/support/tickets")
@RequiredArgsConstructor
@Slf4j
public class FarmerSupportController {

    private final SupportTicketService supportTicketService;

    @PostMapping
    public ResponseEntity<ApiResponse<TicketDetailDto>> createTicket(
            @RequestHeader("X-User-Id") String userIdHeader,
            @Validated @RequestBody CreateTicketRequest request) {

        Long farmerId = Long.valueOf(userIdHeader);
        TicketDetailDto ticket = supportTicketService.createTicket(farmerId, request);
        return ResponseEntity.ok(new ApiResponse<>("Ticket created successfully", ticket));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<TicketSummaryDto>>> getMyTickets(
            @RequestHeader("X-User-Id") String userIdHeader,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Long farmerId = Long.valueOf(userIdHeader);
        Page<TicketSummaryDto> tickets = supportTicketService.getFarmerTickets(farmerId, page, size);
        return ResponseEntity.ok(new ApiResponse<>("Tickets fetched successfully", tickets));
    }

    @GetMapping("/{ticketId}")
    public ResponseEntity<ApiResponse<TicketDetailDto>> getTicketDetail(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long ticketId) {

        Long farmerId = Long.valueOf(userIdHeader);
        return supportTicketService.getFarmerTicketDetail(farmerId, ticketId)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>("Ticket detail fetched successfully", dto)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(new ApiResponse<>("Ticket not found", null)));
    }

    @PostMapping("/{ticketId}/messages")
    public ResponseEntity<ApiResponse<TicketDetailDto>> addMessage(
            @RequestHeader("X-User-Id") String userIdHeader,
            @PathVariable Long ticketId,
            @Validated @RequestBody AddMessageRequest request) {

        Long farmerId = Long.valueOf(userIdHeader);
        return supportTicketService.addFarmerMessage(farmerId, ticketId, request)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>("Message added successfully", dto)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(new ApiResponse<>("Ticket not found", null)));
    }
}

