package com.krushikranti.subscription.repository;

import com.krushikranti.subscription.model.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for PaymentTransaction entity.
 */
@Repository
public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

    /**
     * Find transactions by subscription ID
     */
    List<PaymentTransaction> findBySubscriptionId(Long subscriptionId);

    /**
     * Find transactions by farmer ID
     */
    List<PaymentTransaction> findByFarmerId(Long farmerId);

    /**
     * Find transactions by user ID
     */
    List<PaymentTransaction> findByUserId(Long userId);

    /**
     * Find transaction by gateway order ID
     */
    Optional<PaymentTransaction> findByGatewayOrderId(String gatewayOrderId);

    /**
     * Find pending transactions for a subscription
     */
    List<PaymentTransaction> findBySubscriptionIdAndTransactionStatus(
            Long subscriptionId, 
            PaymentTransaction.TransactionStatus status);
}

