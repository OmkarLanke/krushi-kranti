package com.krushikranti.support.repository;

import com.krushikranti.support.model.SupportTicketMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SupportTicketMessageRepository extends JpaRepository<SupportTicketMessage, Long> {

    List<SupportTicketMessage> findByTicketIdOrderByCreatedAtAsc(Long ticketId);
}

