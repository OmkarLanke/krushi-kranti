package com.krushikranti.subscription.repository;

import com.krushikranti.subscription.model.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for Subscription entity.
 */
@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    /**
     * Find subscription by farmer ID
     */
    Optional<Subscription> findByFarmerId(Long farmerId);

    /**
     * Find subscription by user ID
     */
    Optional<Subscription> findByUserId(Long userId);

    /**
     * Find active subscription by farmer ID
     */
    @Query("SELECT s FROM Subscription s WHERE s.farmerId = :farmerId " +
           "AND s.subscriptionStatus = 'ACTIVE' " +
           "AND s.subscriptionEndDate > :now")
    Optional<Subscription> findActiveSubscriptionByFarmerId(
            @Param("farmerId") Long farmerId,
            @Param("now") LocalDateTime now);

    /**
     * Find active subscription by user ID
     */
    @Query("SELECT s FROM Subscription s WHERE s.userId = :userId " +
           "AND s.subscriptionStatus = 'ACTIVE' " +
           "AND s.subscriptionEndDate > :now")
    Optional<Subscription> findActiveSubscriptionByUserId(
            @Param("userId") Long userId,
            @Param("now") LocalDateTime now);

    /**
     * Find all subscriptions expiring before a given date
     */
    @Query("SELECT s FROM Subscription s WHERE s.subscriptionStatus = 'ACTIVE' " +
           "AND s.subscriptionEndDate < :date")
    List<Subscription> findExpiredSubscriptions(@Param("date") LocalDateTime date);

    /**
     * Find subscriptions expiring soon (for reminder notifications)
     */
    @Query("SELECT s FROM Subscription s WHERE s.subscriptionStatus = 'ACTIVE' " +
           "AND s.subscriptionEndDate BETWEEN :startDate AND :endDate")
    List<Subscription> findSubscriptionsExpiringSoon(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    /**
     * Check if farmer has any subscription (active or expired)
     */
    boolean existsByFarmerId(Long farmerId);

    /**
     * Check if user has any subscription (active or expired)
     */
    boolean existsByUserId(Long userId);
}

