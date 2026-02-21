package com.krushikranti.farmer.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Configuration for WeatherAPI.com integration.
 * 
 * This config sets up the WebClient bean specifically for calling
 * the external weather API service. We use a separate WebClient
 * to isolate weather API calls from other service calls.
 * 
 * @author KrushiKranti Team
 */
@Configuration
public class WeatherApiConfig {

    /**
     * Base URL for WeatherAPI.com
     * Value is injected from application.yml
     * Default: https://api.weatherapi.com/v1
     */
    @Value("${weather.api.base-url:https://api.weatherapi.com/v1}")
    private String weatherApiBaseUrl;

    /**
     * Creates a WebClient bean specifically for weather API calls.
     * 
     * WebClient is Spring's non-blocking HTTP client that works with reactive streams.
     * We configure it with:
     * - Base URL pointing to WeatherAPI.com
     * - Default Accept header for JSON responses
     * - 2MB max in-memory buffer size for large responses
     * 
     * @return WebClient configured for weather API calls
     */
    @Bean(name = "weatherWebClient")
    public WebClient weatherWebClient() {
        return WebClient.builder()
                .baseUrl(weatherApiBaseUrl)
                .defaultHeader("Accept", "application/json")
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(2 * 1024 * 1024)) // 2MB buffer
                .build();
    }
}
