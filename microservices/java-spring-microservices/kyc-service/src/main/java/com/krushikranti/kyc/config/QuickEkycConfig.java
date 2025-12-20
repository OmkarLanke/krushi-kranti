package com.krushikranti.kyc.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for Quick eKYC API integration.
 */
@Configuration
@ConfigurationProperties(prefix = "quickekyc.api")
@Data
public class QuickEkycConfig {
    
    /**
     * Base URL for Quick eKYC API
     * Production: https://api.quickekyc.com
     * Sandbox: https://sandbox.quickekyc.com
     */
    private String baseUrl;
    
    /**
     * API Key for authentication
     */
    private String key;
    
    /**
     * Connection timeout in milliseconds
     */
    private int connectTimeout = 10000;
    
    /**
     * Read timeout in milliseconds
     */
    private int readTimeout = 30000;
}

