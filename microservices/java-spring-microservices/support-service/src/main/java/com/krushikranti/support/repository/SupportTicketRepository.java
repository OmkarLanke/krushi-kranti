package com.krushikranti.support.repository;

import com.krushikranti.support.model.SupportTicket;
import com.krushikranti.support.model.TicketStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SupportTicketRepository extends JpaRepository<SupportTicket, Long> {

    Page<SupportTicket> findByFarmerIdOrderByLastMessageAtDesc(Long farmerId, Pageable pageable);

    Page<SupportTicket> findByStatusOrderByLastMessageAtDesc(TicketStatus status, Pageable pageable);

    Page<SupportTicket> findByFarmerIdAndStatusOrderByLastMessageAtDesc(Long farmerId, TicketStatus status, Pageable pageable);
}

