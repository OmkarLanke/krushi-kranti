package com.krushikranti.gateway.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuration properties for downstream service URLs.
 * Different values can be set for localhost vs Docker environments.
 */
@Component
@ConfigurationProperties(prefix = "gateway.services")
@Data
public class ServiceUrlProperties {
    
    private String authService = "http://localhost:4005";
    private String farmerService = "http://localhost:4000";
    private String fundingService = "http://localhost:4001";
    private String inventoryService = "http://localhost:4002";
    private String procurementService = "http://localhost:4003";
    private String paymentService = "http://localhost:4006";
    private String profileService = "http://localhost:4007";
    private String fileService = "http://localhost:4008";
    private String notificationService = "http://localhost:4009";
    private String chatService = "http://localhost:4010";
    private String advisoryService = "http://localhost:4011";
    private String supportService = "http://localhost:4012";
    private String subscriptionService = "http://localhost:4013";
}

