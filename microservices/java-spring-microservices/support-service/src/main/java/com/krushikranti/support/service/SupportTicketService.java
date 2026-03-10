package com.krushikranti.support.service;

import com.krushikranti.support.dto.AddMessageRequest;
import com.krushikranti.support.dto.CreateTicketRequest;
import com.krushikranti.support.dto.TicketDetailDto;
import com.krushikranti.support.dto.TicketMessageDto;
import com.krushikranti.support.dto.TicketSummaryDto;
import com.krushikranti.support.model.SupportTicket;
import com.krushikranti.support.model.SupportTicketMessage;
import com.krushikranti.support.model.TicketMessageSenderType;
import com.krushikranti.support.model.TicketStatus;
import com.krushikranti.support.repository.SupportTicketMessageRepository;
import com.krushikranti.support.repository.SupportTicketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SupportTicketService {

    private final SupportTicketRepository ticketRepository;
    private final SupportTicketMessageRepository messageRepository;

    @Transactional
    public TicketDetailDto createTicket(Long farmerId, CreateTicketRequest request) {
        log.info("Creating support ticket for farmer {} with title {}", farmerId, request.getTitle());

        SupportTicket ticket = SupportTicket.builder()
                .farmerId(farmerId)
                .title(request.getTitle())
                .category(request.getCategory())
                .status(TicketStatus.OPEN)
                .priority("NORMAL")
                .unreadForAdmin(true)
                .unreadForFarmer(false)
                .source("FARMER_APP")
                .build();

        ticket = ticketRepository.save(ticket);

        SupportTicketMessage firstMessage = SupportTicketMessage.builder()
                .ticket(ticket)
                .senderType(TicketMessageSenderType.FARMER)
                .senderId(farmerId)
                .content(request.getDescription())
                .build();

        firstMessage = messageRepository.save(firstMessage);

        // Update last message metadata
        ticket.setLastMessageAt(firstMessage.getCreatedAt());
        ticket.setLastMessageBy(firstMessage.getSenderType());
        ticket.setUnreadForAdmin(true);
        ticket.setUnreadForFarmer(false);
        ticketRepository.save(ticket);

        return toDetailDto(ticket, List.of(firstMessage));
    }

    @Transactional(readOnly = true)
    public Page<TicketSummaryDto> getFarmerTickets(Long farmerId, int page, int size) {
        Page<SupportTicket> tickets = ticketRepository.findByFarmerIdOrderByLastMessageAtDesc(
                farmerId, PageRequest.of(page, size));
        return tickets.map(this::toSummaryDto);
    }

    @Transactional(readOnly = true)
    public Optional<TicketDetailDto> getFarmerTicketDetail(Long farmerId, Long ticketId) {
        Optional<SupportTicket> ticketOpt = ticketRepository.findById(ticketId)
                .filter(t -> t.getFarmerId().equals(farmerId));

        if (ticketOpt.isEmpty()) {
            return Optional.empty();
        }

        SupportTicket ticket = ticketOpt.get();
        List<SupportTicketMessage> messages = messageRepository.findByTicketIdOrderByCreatedAtAsc(ticketId);

        return Optional.of(toDetailDto(ticket, messages));
    }

    @Transactional
    public Optional<TicketDetailDto> addFarmerMessage(Long farmerId, Long ticketId, AddMessageRequest request) {
        Optional<SupportTicket> ticketOpt = ticketRepository.findById(ticketId)
                .filter(t -> t.getFarmerId().equals(farmerId));

        if (ticketOpt.isEmpty()) {
            return Optional.empty();
        }

        SupportTicket ticket = ticketOpt.get();

        SupportTicketMessage message = SupportTicketMessage.builder()
                .ticket(ticket)
                .senderType(TicketMessageSenderType.FARMER)
                .senderId(farmerId)
                .content(request.getContent())
                .build();

        message = messageRepository.save(message);

        ticket.setLastMessageAt(message.getCreatedAt());
        ticket.setLastMessageBy(message.getSenderType());
        ticket.setUnreadForAdmin(true);
        ticket.setUnreadForFarmer(false);
        ticketRepository.save(ticket);

        List<SupportTicketMessage> messages = messageRepository.findByTicketIdOrderByCreatedAtAsc(ticketId);
        return Optional.of(toDetailDto(ticket, messages));
    }

    @Transactional(readOnly = true)
    public Page<TicketSummaryDto> getAdminTickets(String status, int page, int size) {
        PageRequest pageable = PageRequest.of(page, size);

        if (status == null || status.isBlank()) {
            return ticketRepository.findAll(pageable).map(this::toSummaryDto);
        }

        TicketStatus ticketStatus = TicketStatus.valueOf(status.toUpperCase());
        return ticketRepository.findByStatusOrderByLastMessageAtDesc(ticketStatus, pageable)
                .map(this::toSummaryDto);
    }

    @Transactional(readOnly = true)
    public Optional<TicketDetailDto> getAdminTicketDetail(Long ticketId) {
        Optional<SupportTicket> ticketOpt = ticketRepository.findById(ticketId);
        if (ticketOpt.isEmpty()) {
            return Optional.empty();
        }
        SupportTicket ticket = ticketOpt.get();
        List<SupportTicketMessage> messages = messageRepository.findByTicketIdOrderByCreatedAtAsc(ticketId);

        // Mark as read for admin
        ticket.setUnreadForAdmin(false);
        ticketRepository.save(ticket);

        return Optional.of(toDetailDto(ticket, messages));
    }

    @Transactional
    public Optional<TicketDetailDto> addAdminMessage(Long adminUserId, Long ticketId, AddMessageRequest request) {
        Optional<SupportTicket> ticketOpt = ticketRepository.findById(ticketId);
        if (ticketOpt.isEmpty()) {
            return Optional.empty();
        }

        SupportTicket ticket = ticketOpt.get();

        SupportTicketMessage message = SupportTicketMessage.builder()
                .ticket(ticket)
                .senderType(TicketMessageSenderType.ADMIN)
                .senderId(adminUserId)
                .content(request.getContent())
                .build();

        message = messageRepository.save(message);

        ticket.setLastMessageAt(message.getCreatedAt());
        ticket.setLastMessageBy(message.getSenderType());
        ticket.setUnreadForAdmin(false);
        ticket.setUnreadForFarmer(true);
        ticketRepository.save(ticket);

        List<SupportTicketMessage> messages = messageRepository.findByTicketIdOrderByCreatedAtAsc(ticketId);
        return Optional.of(toDetailDto(ticket, messages));
    }

    @Transactional
    public Optional<TicketDetailDto> updateStatus(Long ticketId, TicketStatus status) {
        Optional<SupportTicket> ticketOpt = ticketRepository.findById(ticketId);
        if (ticketOpt.isEmpty()) {
            return Optional.empty();
        }

        SupportTicket ticket = ticketOpt.get();
        ticket.setStatus(status);
        ticket.setUpdatedAt(LocalDateTime.now());
        ticket = ticketRepository.save(ticket);

        List<SupportTicketMessage> messages = messageRepository.findByTicketIdOrderByCreatedAtAsc(ticketId);
        return Optional.of(toDetailDto(ticket, messages));
    }

    private TicketSummaryDto toSummaryDto(SupportTicket ticket) {
        return TicketSummaryDto.builder()
                .id(ticket.getId())
                .title(ticket.getTitle())
                .category(ticket.getCategory())
                .status(ticket.getStatus())
                .priority(ticket.getPriority())
                .createdAt(ticket.getCreatedAt())
                .updatedAt(ticket.getUpdatedAt())
                .lastMessageAt(ticket.getLastMessageAt())
                .lastMessageBy(ticket.getLastMessageBy())
                .unreadForFarmer(ticket.isUnreadForFarmer())
                .unreadForAdmin(ticket.isUnreadForAdmin())
                .build();
    }

    private TicketDetailDto toDetailDto(SupportTicket ticket, List<SupportTicketMessage> messages) {
        List<TicketMessageDto> messageDtos = messages.stream()
                .map(m -> TicketMessageDto.builder()
                        .id(m.getId())
                        .senderType(m.getSenderType())
                        .senderId(m.getSenderId())
                        .content(m.getContent())
                        .createdAt(m.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        return TicketDetailDto.builder()
                .id(ticket.getId())
                .farmerId(ticket.getFarmerId())
                .title(ticket.getTitle())
                .category(ticket.getCategory())
                .status(ticket.getStatus())
                .priority(ticket.getPriority())
                .assignedAdminId(ticket.getAssignedAdminId())
                .createdAt(ticket.getCreatedAt())
                .updatedAt(ticket.getUpdatedAt())
                .messages(messageDtos)
                .build();
    }
}

