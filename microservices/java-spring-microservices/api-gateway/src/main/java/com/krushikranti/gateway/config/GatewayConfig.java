package com.krushikranti.gateway.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;

/**
 * Gateway routing configuration.
 * Uses ServiceUrlProperties for environment-aware service URLs.
 */
@Configuration
@RequiredArgsConstructor
@Slf4j
public class GatewayConfig {

    private final ServiceUrlProperties serviceUrls;

    @PostConstruct
    public void init() {
        log.info("Gateway configured with service URLs:");
        log.info("  Auth Service: {}", serviceUrls.getAuthService());
        log.info("  Farmer Service: {}", serviceUrls.getFarmerService());
        log.info("  Subscription Service: {}", serviceUrls.getSubscriptionService());
        log.info("  KYC Service: {}", serviceUrls.getKycService());
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                // JWKS endpoint (must be before auth routes to avoid path conflicts)
                .route("jwks-endpoint", r -> r
                        .path("/.well-known/**")
                        .uri(serviceUrls.getAuthService()))
                
                // Auth Service Routes
                .route("auth-service", r -> r
                        .path("/auth/**")
                        .uri(serviceUrls.getAuthService()))
                
                // Farmer Service Routes
                .route("farmer-service", r -> r
                        .path("/farmer/**")
                        .uri(serviceUrls.getFarmerService()))
                
                // Funding Service Routes
                .route("funding-service", r -> r
                        .path("/funding/**")
                        .uri(serviceUrls.getFundingService()))
                
                // Inventory Service Routes
                .route("inventory-service", r -> r
                        .path("/inventory/**")
                        .uri(serviceUrls.getInventoryService()))
                
                // Procurement Service Routes
                .route("procurement-service", r -> r
                        .path("/procurement/**")
                        .uri(serviceUrls.getProcurementService()))
                
                // Payment Service Routes
                .route("payment-service", r -> r
                        .path("/payment/**")
                        .uri(serviceUrls.getPaymentService()))
                
                // Profile Service Routes
                .route("profile-service", r -> r
                        .path("/profile/**")
                        .uri(serviceUrls.getProfileService()))
                
                // File/Media Service Routes
                .route("file-service", r -> r
                        .path("/file/**")
                        .uri(serviceUrls.getFileService()))
                
                // Notification Service Routes
                .route("notification-service", r -> r
                        .path("/notification/**")
                        .uri(serviceUrls.getNotificationService()))
                
                // Chat/Tadnya Service Routes
                .route("chat-service", r -> r
                        .path("/chat/**")
                        .uri(serviceUrls.getChatService()))
                
                // Advisory Service Routes
                .route("advisory-service", r -> r
                        .path("/advisory/**")
                        .uri(serviceUrls.getAdvisoryService()))
                
                // Support Service Routes
                .route("support-service", r -> r
                        .path("/support/**")
                        .uri(serviceUrls.getSupportService()))
                
                // Subscription Service Routes
                .route("subscription-service", r -> r
                        .path("/subscription/**")
                        .uri(serviceUrls.getSubscriptionService()))
                
                // KYC Service Routes
                .route("kyc-service", r -> r
                        .path("/kyc/**")
                        .uri(serviceUrls.getKycService()))
                
                .build();
    }
}
