package com.krushikranti.support.controller;

import com.krushikranti.support.dto.AddMessageRequest;
import com.krushikranti.support.dto.ApiResponse;
import com.krushikranti.support.dto.TicketDetailDto;
import com.krushikranti.support.dto.TicketSummaryDto;
import com.krushikranti.support.dto.UpdateTicketStatusRequest;
import com.krushikranti.support.model.TicketStatus;
import com.krushikranti.support.service.SupportTicketService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/support/admin/tickets")
@RequiredArgsConstructor
@Slf4j
public class AdminSupportController {

    private final SupportTicketService supportTicketService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<TicketSummaryDto>>> getAllTickets(
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }

        Page<TicketSummaryDto> tickets = supportTicketService.getAdminTickets(status, page, size);
        return ResponseEntity.ok(new ApiResponse<>("Tickets fetched successfully", tickets));
    }

    @GetMapping("/{ticketId}")
    public ResponseEntity<ApiResponse<TicketDetailDto>> getTicketDetail(
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles,
            @PathVariable Long ticketId) {

        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }

        return supportTicketService.getAdminTicketDetail(ticketId)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>("Ticket detail fetched successfully", dto)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(new ApiResponse<>("Ticket not found", null)));
    }

    @PostMapping("/{ticketId}/messages")
    public ResponseEntity<ApiResponse<TicketDetailDto>> addMessage(
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles,
            @PathVariable Long ticketId,
            @Validated @RequestBody AddMessageRequest request) {

        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }

        Long adminId = adminUserId != null ? Long.valueOf(adminUserId) : 0L;

        return supportTicketService.addAdminMessage(adminId, ticketId, request)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>("Message added successfully", dto)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(new ApiResponse<>("Ticket not found", null)));
    }

    @PutMapping("/{ticketId}/status")
    public ResponseEntity<ApiResponse<TicketDetailDto>> updateStatus(
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String roles,
            @PathVariable Long ticketId,
            @Validated @RequestBody UpdateTicketStatusRequest request) {

        if (roles == null || !roles.contains("ADMIN")) {
            return ResponseEntity.status(403)
                    .body(new ApiResponse<>("Access denied. Admin role required.", null));
        }

        TicketStatus status = request.getStatus();

        return supportTicketService.updateStatus(ticketId, status)
                .map(dto -> ResponseEntity.ok(new ApiResponse<>("Ticket status updated successfully", dto)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(new ApiResponse<>("Ticket not found", null)));
    }
}

