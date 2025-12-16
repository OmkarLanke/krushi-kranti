package com.krushikranti.subscription.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

/**
 * Configuration properties for subscription settings.
 */
@Configuration
@ConfigurationProperties(prefix = "subscription")
@Data
public class SubscriptionConfig {

    private BigDecimal amount = new BigDecimal("999.00");
    private String currency = "INR";
    private Integer validityDays = 365;
    private Integer trialDays = 0;
}

